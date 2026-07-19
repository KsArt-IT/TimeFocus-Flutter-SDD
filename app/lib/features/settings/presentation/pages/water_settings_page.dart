import 'dart:async';

import 'package:flutter/material.dart';

import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/water_reminder_mode.dart';
import 'package:timefocus/shared/widgets/drink_localization.dart';

/// T078: goal mode/value, reminder mode (interval or scheduled times),
/// quick-add buttons, toilet-suggestion flags.
class WaterSettingsPage extends StatefulWidget {
  const WaterSettingsPage({super.key});

  @override
  State<WaterSettingsPage> createState() => _WaterSettingsPageState();
}

class _WaterSettingsPageState extends State<WaterSettingsPage> {
  bool _loading = true;
  late WaterSettingsEntity _settings;
  List<int> _reminderTimes = const [];

  WaterRepository get _repo => getIt<WaterRepository>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final settingsResult = await _repo.currentSettings();
    final timesResult = await _repo.reminderTimes();
    if (!mounted) return;
    setState(() {
      _settings = settingsResult.valueOrNull ?? const WaterSettingsEntity();
      _reminderTimes = timesResult.valueOrNull ?? const [];
      _loading = false;
    });
  }

  Future<void> _save() async {
    final result = await _repo.saveSettings(_settings);
    if (!mounted) return;
    if (result.isFailure) {
      logger.e('failed to save water settings', error: result.errorOrNull);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).done)),
    );
  }

  Future<void> _addReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    final times = [..._reminderTimes, minutes]..sort();
    final result = await _repo.saveReminderTimes(times);
    if (!mounted) return;
    if (result.isFailure) {
      logger.e('failed to save reminder times', error: result.errorOrNull);
      return;
    }
    setState(() => _reminderTimes = times);
  }

  Future<void> _removeReminderTime(int minutes) async {
    final times = _reminderTimes.where((t) => t != minutes).toList();
    final result = await _repo.saveReminderTimes(times);
    if (!mounted) return;
    if (result.isFailure) {
      logger.e('failed to save reminder times', error: result.errorOrNull);
      return;
    }
    setState(() => _reminderTimes = times);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsWater)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsWater),
        actions: [
          IconButton(icon: const Icon(Icons.check), tooltip: l10n.save, onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.waterGoal, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.waterGoalModeManual)),
              ButtonSegment(value: true, label: Text(l10n.waterGoalModeByWeight)),
            ],
            selected: {_settings.weightMode},
            onSelectionChanged: (s) =>
                setState(() => _settings = _settings.copyWith(weightMode: s.first)),
          ),
          const SizedBox(height: 8),
          if (_settings.weightMode)
            _NumberField(
              label: l10n.waterWeightKg,
              value: _settings.weightKg,
              onChanged: (v) => setState(() => _settings = _settings.copyWith(weightKg: v)),
            )
          else
            _NumberField(
              label: l10n.waterGoal,
              value: _settings.dailyWaterGoal,
              step: 100,
              onChanged: (v) => setState(() => _settings = _settings.copyWith(dailyWaterGoal: v)),
            ),
          _NumberField(
            label: l10n.waterExtraLoad,
            value: _settings.extraLoad,
            step: 100,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(extraLoad: v)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(l10n.waterExtraLoadHint, style: Theme.of(context).textTheme.bodySmall),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.waterReminderRemindersEnabled),
            value: _settings.remindersEnabled,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(remindersEnabled: v)),
          ),
          SegmentedButton<WaterReminderMode>(
            segments: [
              ButtonSegment(
                value: WaterReminderMode.interval,
                label: Text(l10n.waterReminderModeInterval),
              ),
              ButtonSegment(
                value: WaterReminderMode.scheduled,
                label: Text(l10n.waterReminderModeScheduled),
              ),
            ],
            selected: {_settings.reminderMode},
            onSelectionChanged: (s) =>
                setState(() => _settings = _settings.copyWith(reminderMode: s.first)),
          ),
          const SizedBox(height: 8),
          if (_settings.reminderMode == WaterReminderMode.interval)
            _NumberField(
              label: l10n.waterReminderInterval(_settings.reminderInterval),
              value: _settings.reminderInterval,
              step: 5,
              onChanged: (v) => setState(() => _settings = _settings.copyWith(reminderInterval: v)),
            )
          else ...[
            Text(l10n.waterReminderTimes, style: Theme.of(context).textTheme.labelLarge),
            for (final minutes in _reminderTimes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(_formatMinutes(minutes)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeReminderTime(minutes),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _addReminderTime,
              icon: const Icon(Icons.add),
              label: Text(l10n.waterReminderAddTime),
            ),
          ],
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showToiletOnWater),
            value: _settings.showToiletOnWater,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(showToiletOnWater: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showToiletOnBreak),
            value: _settings.showToiletOnBreak,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(showToiletOnBreak: v)),
          ),
          const Divider(),
          Text(l10n.waterQuickButtons, style: Theme.of(context).textTheme.labelLarge),
          const _QuickButtonsList(),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => onChanged((value - step).clamp(0, 100000)),
          ),
          Text('$value'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged((value + step).clamp(0, 100000)),
          ),
        ],
      ),
    );
  }
}

class _QuickButtonsList extends StatefulWidget {
  const _QuickButtonsList();

  @override
  State<_QuickButtonsList> createState() => _QuickButtonsListState();
}

class _QuickButtonsListState extends State<_QuickButtonsList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WaterQuickButtonEntity>>(
      stream: getIt<WaterRepository>().watchQuickButtons(),
      builder: (context, snapshot) {
        final buttons = snapshot.data ?? const [];
        return Column(
          children: [
            for (final button in buttons) _QuickButtonTile(button: button),
          ],
        );
      },
    );
  }
}

class _QuickButtonTile extends StatelessWidget {
  const _QuickButtonTile({required this.button});

  final WaterQuickButtonEntity button;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(button.label.localizedLabel(l10n)),
      subtitle: Text(l10n.drinkVolumeMl(button.volume)),
      value: button.isActive,
      onChanged: (v) async {
        final result = await getIt<WaterRepository>().saveQuickButton(
          button.copyWith(isActive: v),
        );
        if (result.isFailure) {
          logger.e('failed to toggle quick button', error: result.errorOrNull);
        }
      },
    );
  }
}
