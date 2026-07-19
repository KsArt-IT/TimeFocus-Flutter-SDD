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
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

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
