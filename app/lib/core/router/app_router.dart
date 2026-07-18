import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:timefocus/app/shell/shell_page.dart';
import 'package:timefocus/features/history/presentation/pages/history_page.dart';
import 'package:timefocus/features/schedule/presentation/pages/schedule_page.dart';
import 'package:timefocus/features/tracker/presentation/pages/tracker_page.dart';

/// Route paths used across the app (deep links included).
abstract final class AppRoutes {
  static const String tracker = '/tracker';
  static const String schedule = '/schedule';
  static const String history = '/history';
  static const String onboarding = '/onboarding';
  static const String more = '/more';
  static const String settings = '/settings';
  static const String actionEdit = '/action/edit';
  static const String intervalEdit = '/interval/edit';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.tracker,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ShellPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tracker,
              builder: (context, state) => const TrackerPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.schedule,
              builder: (context, state) => const SchedulePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (context, state) => const HistoryPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
