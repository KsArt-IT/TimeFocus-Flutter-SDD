import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:timefocus/gen/app_localizations.dart';

/// Shell scaffold: HUD panel slot on top, tab content, bottom navigation.
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
            const _HudSlot(),
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

/// HUD panel placeholder — replaced by HudPanel in US3 (T044).
class _HudSlot extends StatelessWidget {
  const _HudSlot();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
