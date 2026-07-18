import 'package:flutter/material.dart' show ThemeMode;

/// Application theme mode stored in user settings.
enum AppThemeMode {
  dark,
  light,
  system;

  factory AppThemeMode.fromIndex(int index) =>
      AppThemeMode.values.asMap()[index] ?? AppThemeMode.system;

  ThemeMode get themeMode => switch (this) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.system => ThemeMode.system,
  };
}
