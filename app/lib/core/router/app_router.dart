import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:timefocus/app/shell/shell_page.dart';
import 'package:timefocus/features/history/presentation/pages/history_page.dart';
import 'package:timefocus/features/history/presentation/pages/interval_edit_page.dart';
import 'package:timefocus/features/history/presentation/pages/reports_page.dart';
import 'package:timefocus/features/history/presentation/pages/session_edit_page.dart';
import 'package:timefocus/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:timefocus/features/schedule/presentation/pages/schedule_page.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:timefocus/features/settings/presentation/pages/action_edit_page.dart';
import 'package:timefocus/features/settings/presentation/pages/actions_settings_page.dart';
import 'package:timefocus/features/settings/presentation/pages/more_page.dart';
import 'package:timefocus/features/settings/presentation/pages/pomodoro_settings_page.dart';
import 'package:timefocus/features/settings/presentation/pages/reminders_settings_page.dart';
import 'package:timefocus/features/settings/presentation/pages/schedule_settings_page.dart';
import 'package:timefocus/features/settings/presentation/pages/system_settings_page.dart';
import 'package:timefocus/features/settings/presentation/pages/water_settings_page.dart';
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
  static const String sessionEdit = '/session/edit';
  static const String reports = '/reports';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// T085: onboardingCompleted == false → /onboarding, and back once done —
/// re-evaluated whenever [settingsCubit] emits (Drift stream, FR-044).
GoRouter createAppRouter(AppSettingsCubit settingsCubit) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.tracker,
  refreshListenable: _GoRouterRefreshStream(settingsCubit.stream),
  redirect: (context, state) {
    final settings = settingsCubit.state;
    if (!settings.ready) return null;
    final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
    if (!settings.settings.onboardingCompleted) {
      return atOnboarding ? null : AppRoutes.onboarding;
    }
    return atOnboarding ? AppRoutes.tracker : null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),
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
    // Outside the shell (no HUD/bottom nav) — full-screen editors.
    GoRoute(
      path: '${AppRoutes.sessionEdit}/:id',
      builder: (context, state) => SessionEditPage(
        historyId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '${AppRoutes.intervalEdit}/:historyId',
      builder: (context, state) {
        final intervalId = state.uri.queryParameters['intervalId'];
        return IntervalEditPage(
          historyId: int.parse(state.pathParameters['historyId']!),
          intervalId: intervalId == null ? null : int.parse(intervalId),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.reports,
      builder: (context, state) => const ReportsPage(),
    ),
    GoRoute(
      path: AppRoutes.more,
      builder: (context, state) => const MorePage(),
    ),
    GoRoute(
      path: AppRoutes.actionEdit,
      builder: (context, state) => const ActionEditPage(),
    ),
    GoRoute(
      path: '${AppRoutes.actionEdit}/:id',
      builder: (context, state) => ActionEditPage(actionId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '${AppRoutes.settings}/system',
      builder: (context, state) => const SystemSettingsPage(),
    ),
    GoRoute(
      path: '${AppRoutes.settings}/actions',
      builder: (context, state) => const ActionsSettingsPage(),
    ),
    GoRoute(
      path: '${AppRoutes.settings}/pomodoro',
      builder: (context, state) => const PomodoroSettingsPage(),
    ),
    GoRoute(
      path: '${AppRoutes.settings}/water',
      builder: (context, state) => const WaterSettingsPage(),
    ),
    GoRoute(
      path: '${AppRoutes.settings}/reminders',
      builder: (context, state) => const RemindersSettingsPage(),
    ),
    GoRoute(
      path: '${AppRoutes.settings}/schedule',
      builder: (context, state) => const ScheduleSettingsPage(),
    ),
  ],
);

/// Notifies go_router to re-run `redirect` on every cubit emission.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
