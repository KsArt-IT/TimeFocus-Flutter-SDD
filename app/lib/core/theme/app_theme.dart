import 'package:flutter/material.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/core/theme/app_colors.dart';

/// Light and dark application themes.
abstract final class AppTheme {
  static const Color _seed = AppColors.seed;

  static ThemeData get light => _build(.light);

  static ThemeData get dark => _build(.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        margin: .symmetric(
          horizontal: AppDimens.radius3x,
          vertical: AppDimens.radius4x,
        ),
        shape: RoundedRectangleBorder(borderRadius: .all(.circular(AppDimens.radius4x))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: .floating),
    );
  }
}
