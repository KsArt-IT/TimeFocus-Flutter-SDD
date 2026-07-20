import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/core/router/app_router.dart';
import 'package:timefocus/core/system_ui/system_ui_manager.dart';
import 'package:timefocus/core/theme/app_theme.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:toastification/toastification.dart';

/// MaterialApp.router bound to AppSettingsCubit: instant theme/locale switch.
class AppMaterialRouter extends StatefulWidget {
  const AppMaterialRouter({super.key});

  @override
  State<AppMaterialRouter> createState() => _AppMaterialRouterState();
}

class _AppMaterialRouterState extends State<AppMaterialRouter> {
  late final GoRouter _router = createAppRouter(context.read<AppSettingsCubit>());

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SystemUiManager.updateSystemUi(
            state.settings.themeMode.themeMode,
            MediaQuery.platformBrightnessOf(context),
          );
        });

        return ToastificationWrapper(
          child: MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: state.settings.themeMode.themeMode,
            locale: state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _router,
          ),
        );
      },
    );
  }
}
