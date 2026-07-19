import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:timefocus/core/router/app_router.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// T074: "More" section — entry points to every settings screen, plus
/// account/about stubs (FR-045). Reached from the shell's bottom nav.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settingsAccount),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openStub(context, l10n.settingsAccount),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l10n.settingsDisplay),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('${AppRoutes.settings}/system'),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_outlined),
            title: Text(l10n.settingsActions),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('${AppRoutes.settings}/actions'),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.settingsPomodoro),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('${AppRoutes.settings}/pomodoro'),
          ),
          ListTile(
            leading: const Icon(Icons.local_drink_outlined),
            title: Text(l10n.settingsWater),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('${AppRoutes.settings}/water'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(l10n.settingsSchedule),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('${AppRoutes.settings}/schedule'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.settingsNotifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('${AppRoutes.settings}/reminders'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAbout),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openAbout(context),
          ),
        ],
      ),
    );
  }

  void _openStub(BuildContext context, String title) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => _StubPage(title: title)),
      ),
    );
  }

  void _openAbout(BuildContext context) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const _AboutPage()),
      ),
    );
  }
}

class _StubPage extends StatelessWidget {
  const _StubPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(l10n.comingSoon)),
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAbout)),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.appTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (info != null) Text(l10n.settingsVersion(info.version)),
                const SizedBox(height: 8),
                Text(l10n.copyright, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}
