import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/app/app_material_router.dart';
import 'package:timefocus/app/root_bloc_listener.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:timefocus/features/pomodoro/presentation/bloc/pomodoro_bloc.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_cubit.dart';

/// Application root: provides all global Bloc/Cubit singletons.
/// Coordination between them happens only in [RootBlocListener].
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resuming from background re-runs rescheduleAll (FR-035a), which
    // re-derives every scheduledAt from local time — the guard against a
    // system clock/timezone change made while the app was backgrounded.
    if (state == AppLifecycleState.resumed) {
      getIt<NotificationBloc>().add(const NotificationEvent.initialized());
    }
  }

  @override
  Widget build(BuildContext context) {
    final hudCubit = getIt<HudCubit>();
    unawaited(hudCubit.subscribe());
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsCubit>.value(
          value: getIt<AppSettingsCubit>(),
        ),
        BlocProvider<ActionBloc>.value(
          value: getIt<ActionBloc>()..add(const ActionEvent.subscribed()),
        ),
        BlocProvider<PomodoroBloc>.value(
          value: getIt<PomodoroBloc>()..add(const PomodoroEvent.recovered()),
        ),
        BlocProvider<HudCubit>.value(
          value: hudCubit,
        ),
        BlocProvider<NotificationBloc>.value(
          value: getIt<NotificationBloc>()..add(const NotificationEvent.initialized()),
        ),
      ],
      child: const RootBlocListener(child: AppMaterialRouter()),
    );
  }
}
