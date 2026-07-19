import 'dart:async';

import 'package:flutter/material.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_settings_entity.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_settings_repository.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/pomodoro_after_action.dart';

/// T077: Pomodoro durations, cycle length, after-action, sound/vibration.
/// Every save creates a new PomodoroSettings row (data-model.md) — running
/// sessions keep referencing the version active when they started, so past
/// statistics never get rewritten by a later settings change.
class PomodoroSettingsPage extends StatefulWidget {
  const PomodoroSettingsPage({super.key});

  @override
  State<PomodoroSettingsPage> createState() => _PomodoroSettingsPageState();
}

class _PomodoroSettingsPageState extends State<PomodoroSettingsPage> {
  bool _loading = true;
  late PomodoroSettingsEntity _settings;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await getIt<PomodoroSettingsRepository>().current();
    if (!mounted) return;
    setState(() {
      _settings = result.valueOrNull ?? PomodoroSettingsEntity(createdAt: DateTime.now());
      _loading = false;
    });
  }

  Future<void> _save() async {
    final result = await getIt<PomodoroSettingsRepository>().saveNewVersion(
      _settings.copyWith(createdAt: DateTime.now()),
    );
    if (!mounted) return;
    if (result.isFailure) {
      logger.e('failed to save pomodoro settings', error: result.errorOrNull);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).done)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.pomodoroSettings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pomodoroSettings),
        actions: [
          IconButton(icon: const Icon(Icons.check), tooltip: l10n.save, onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MinutesField(
            label: l10n.pomodoroSettingsShortWork,
            seconds: _settings.shortWorkTime,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(shortWorkTime: v)),
          ),
          _MinutesField(
            label: l10n.pomodoroSettingsNormalWork,
            seconds: _settings.normalWorkTime,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(normalWorkTime: v)),
          ),
          _MinutesField(
            label: l10n.pomodoroSettingsLongWork,
            seconds: _settings.longWorkTime,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(longWorkTime: v)),
          ),
          _MinutesField(
            label: l10n.pomodoroSettingsShortBreak,
            seconds: _settings.shortBreakTime,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(shortBreakTime: v)),
          ),
          _MinutesField(
            label: l10n.pomodoroSettingsLongBreak,
            seconds: _settings.longBreakTime,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(longBreakTime: v)),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.pomodoroSettingsCycles),
            trailing: DropdownButton<int>(
              value: _settings.cyclesBeforeLongBreak,
              items: [
                for (
                  var c = AppConstants.minCyclesBeforeLongBreak;
                  c <= AppConstants.maxCyclesBeforeLongBreak;
                  c++
                )
                  DropdownMenuItem(value: c, child: Text('$c')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _settings = _settings.copyWith(cyclesBeforeLongBreak: v));
                }
              },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.pomodoroSettingsEscalate),
            subtitle: Text(l10n.pomodoroSettingsEscalateHint),
            value: _settings.escalateIntervals,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(escalateIntervals: v)),
          ),
          const SizedBox(height: 12),
          Text(l10n.pomodoroSettingsAfterAction, style: Theme.of(context).textTheme.labelLarge),
          DropdownButtonFormField<PomodoroAfterAction>(
            initialValue: _settings.afterAction,
            items: [
              for (final action in PomodoroAfterAction.values)
                DropdownMenuItem(value: action, child: Text(_afterActionLabel(l10n, action))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _settings = _settings.copyWith(afterAction: v));
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.pomodoroSettingsSound),
            value: _settings.soundEnabled,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(soundEnabled: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.pomodoroSettingsVibration),
            value: _settings.vibrationEnabled,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(vibrationEnabled: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.pomodoroSettingsNotifications),
            value: _settings.notificationEnabled,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(notificationEnabled: v)),
          ),
        ],
      ),
    );
  }

  String _afterActionLabel(AppLocalizations l10n, PomodoroAfterAction action) => switch (action) {
    PomodoroAfterAction.doNothing => l10n.pomodoroAfterDoNothing,
    PomodoroAfterAction.autoStartBreak => l10n.pomodoroAfterAutoStartBreak,
    PomodoroAfterAction.suggestBreak => l10n.pomodoroAfterSuggestBreak,
    PomodoroAfterAction.repeatSame => l10n.pomodoroAfterRepeatSame,
    PomodoroAfterAction.autoStartWork => l10n.pomodoroAfterAutoStartWork,
  };
}

/// Minutes-facing field over a seconds-based settings value.
class _MinutesField extends StatelessWidget {
  const _MinutesField({required this.label, required this.seconds, required this.onChanged});

  final String label;
  final int seconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => onChanged(((seconds ~/ 60) - 1).clamp(1, 180) * 60),
          ),
          Text(l10n.minutes(seconds ~/ 60)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(((seconds ~/ 60) + 1).clamp(1, 180) * 60),
          ),
        ],
      ),
    );
  }
}
