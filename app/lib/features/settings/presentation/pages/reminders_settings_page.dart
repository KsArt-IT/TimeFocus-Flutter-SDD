import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/notifications/data/datasources/notification_permission_service.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// T079: global notifications toggle + OS permission status/request/open
/// settings (app_settings package).
class RemindersSettingsPage extends StatefulWidget {
  const RemindersSettingsPage({super.key});

  @override
  State<RemindersSettingsPage> createState() => _RemindersSettingsPageState();
}

class _RemindersSettingsPageState extends State<RemindersSettingsPage> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshPermission());
  }

  Future<void> _refreshPermission() async {
    final granted = await getIt<NotificationPermissionService>().isGranted();
    if (mounted) setState(() => _granted = granted);
  }

  Future<void> _requestPermission() async {
    await getIt<NotificationPermissionService>().request();
    await _refreshPermission();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
      body: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, state) {
          final cubit = context.read<AppSettingsCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsNotificationsGlobalMute),
                subtitle: Text(l10n.settingsNotificationsEnabled),
                value: state.settings.notificationsEnabled,
                onChanged: (v) => cubit.setNotificationsEnabled(enabled: v),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.permissionNotificationTitle),
                subtitle: Text(_granted == null ? '…' : (_granted! ? l10n.enabled : l10n.disabled)),
                trailing: Icon(
                  _granted == true ? Icons.check_circle : Icons.error_outline,
                  color: _granted == true
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
              if (_granted != true) ...[
                FilledButton(
                  onPressed: _requestPermission,
                  child: Text(l10n.requestNotificationPermission),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.notification),
                  child: Text(l10n.openNotificationSettings),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
