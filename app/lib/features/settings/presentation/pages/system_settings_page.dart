import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/app_theme_mode.dart';

/// T075: theme/language/time-format — all instant via [AppSettingsCubit]'s
/// reactive Drift stream (FR/SC-008).
class SystemSettingsPage extends StatelessWidget {
  const SystemSettingsPage({super.key});

  static const _languages = ['system', 'en', 'uk', 'ru'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsDisplay)),
      body: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, state) {
          final cubit = context.read<AppSettingsCubit>();
          final settings = state.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.theme, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<AppThemeMode>(
                segments: [
                  ButtonSegment(value: AppThemeMode.system, label: Text(l10n.themeSystem)),
                  ButtonSegment(value: AppThemeMode.light, label: Text(l10n.themeLight)),
                  ButtonSegment(value: AppThemeMode.dark, label: Text(l10n.themeDark)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => cubit.setThemeMode(s.first),
              ),
              const SizedBox(height: 24),
              Text(l10n.language, style: Theme.of(context).textTheme.labelLarge),
              DropdownButtonFormField<String>(
                initialValue: _languages.contains(settings.language) ? settings.language : 'system',
                items: [
                  for (final lang in _languages)
                    DropdownMenuItem(
                      value: lang,
                      child: Text(lang == 'system' ? l10n.languageSystem : lang.toUpperCase()),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) unawaited(cubit.setLanguage(v));
                },
              ),
              const SizedBox(height: 24),
              Text(l10n.timeFormat, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('12h')),
                  ButtonSegment(value: 1, label: Text('24h')),
                ],
                selected: {settings.timeFormat},
                onSelectionChanged: (s) => cubit.setTimeFormat(s.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.shortTime),
                value: settings.isShortTime,
                onChanged: (v) => cubit.setShortTime(isShortTime: v),
              ),
              const SizedBox(height: 24),
              Text(l10n.actionView, style: Theme.of(context).textTheme.labelLarge),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.columnCount),
                trailing: DropdownButton<int>(
                  value: settings.columnCount,
                  items: [
                    for (var i = 1; i <= 5; i++) DropdownMenuItem(value: i, child: Text('$i')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      unawaited(cubit.setGridSize(columns: v, rows: settings.rowCount));
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.rowCount),
                trailing: DropdownButton<int>(
                  value: settings.rowCount,
                  items: [
                    for (var i = 1; i <= 5; i++) DropdownMenuItem(value: i, child: Text('$i')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      unawaited(cubit.setGridSize(columns: settings.columnCount, rows: v));
                    }
                  },
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.rowCountAdaptive),
                subtitle: Text(l10n.rowCountAdaptiveDescription),
                value: settings.rowCountAdaptive,
                onChanged: (v) => cubit.setRowCountAdaptive(adaptive: v),
              ),
            ],
          );
        },
      ),
    );
  }
}
