import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:timefocus/app/shell/widgets/hud_panel.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// Shell scaffold: HUD panel on top, tab content, bottom navigation.
class ShellPage extends StatelessWidget {
  const ShellPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HudPanel(),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.timer_outlined), label: l10n.navTracker),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            label: l10n.navSchedule,
          ),
          NavigationDestination(icon: const Icon(Icons.history), label: l10n.navHistory),
        ],
      ),
    );
  }
}
