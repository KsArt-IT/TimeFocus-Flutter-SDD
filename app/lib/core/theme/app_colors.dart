import 'package:flutter/material.dart';

/// Base palette shared by themes and the system UI manager.
abstract final class AppColors {
  /// Seed for Material 3 color schemes.
  static const Color seed = Color(0xFF2E7D6B);

  static const Color backgroundLight = Color(0xFFF8FAF8);
  static const Color backgroundDark = Color(0xFF111412);

  static const Color navBar = Color(0xFFEDF1EE);
  static const Color navBarDark = Color(0xFF1A1E1B);

  /// Matches flutter_native_splash.yaml — bridges the native splash and the
  /// real themed UI while AppSettingsCubit is still loading, so the swap to
  /// light/dark theme never flashes on top of already-rendered content.
  static const Color splashBackground = Color(0xFF8FBAFC);
}
