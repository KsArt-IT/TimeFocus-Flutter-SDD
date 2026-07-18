import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/app/app_material_router.dart';
import 'package:timefocus/app/root_bloc_listener.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';

/// Application root: provides all global Bloc/Cubit singletons.
/// Coordination between them happens only in [RootBlocListener].
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsCubit>.value(value: getIt<AppSettingsCubit>()),
        // ActionBloc (US1), PomodoroBloc (US2), HudCubit (US3),
        // NotificationBloc (US5) are registered as they are implemented.
      ],
      child: const RootBlocListener(child: AppMaterialRouter()),
    );
  }
}
