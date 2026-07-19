import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/app/shell/widgets/hud_panel.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// Shell scaffold: HUD panel on top, tab content, bottom navigation.
class ShellPage extends StatelessWidget {
  const ShellPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Branch index of the History tab (see AppRoutes/createAppRouter) — the
  /// HUD panel gets in the way of History's own bottom navigation there.
  static const int _historyBranchIndex = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: navigationShell),
            if (navigationShell.currentIndex != _historyBranchIndex) const HudPanel(),
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
