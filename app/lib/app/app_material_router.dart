import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/router/app_router.dart';
import 'package:timefocus/core/system_ui/system_ui_manager.dart';
import 'package:timefocus/core/theme/app_colors.dart';
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
  Timer? _splashFallbackTimer;
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();
    // Keep the native splash up until real settings arrive, so the user never
    // sees a flash of default theme/language before the loaded ones apply.
    if (context.read<AppSettingsCubit>().state.ready) {
      _removeSplash();
    } else {
      _splashFallbackTimer = Timer(AppConstants.splashFallbackTimeout, _removeSplash);
    }
  }

  void _removeSplash() {
    if (_splashRemoved) return;
    _splashRemoved = true;
    _splashFallbackTimer?.cancel();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _splashFallbackTimer?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppSettingsCubit, AppSettingsState>(
      listener: (context, state) {
        if (state.ready) _removeSplash();
      },
      builder: (context, state) {
        // Android 12+ dismisses the native splash on its own schedule, so the
        // real (already themed) UI must never be built before settings are
        // ready — otherwise it briefly renders with the default theme. This
        // bridge mirrors the splash background until the real settings load.
        if (!state.ready) {
          return const _SplashBridge();
        }

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

/// Neutral placeholder shown while [AppSettingsCubit] loads, matching the
/// native splash background so no themed content is visible underneath it.
class _SplashBridge extends StatelessWidget {
  const _SplashBridge();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(color: AppColors.splashBackground),
    );
  }
}
