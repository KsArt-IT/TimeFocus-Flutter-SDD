import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/shared/enums/app_theme_mode.dart';

part 'user_settings_entity.freezed.dart';

@freezed
abstract class UserSettingsEntity with _$UserSettingsEntity {
  const factory UserSettingsEntity({
    @Default('') String name,
    @Default(AppConstants.defaultGridColumns) int columnCount,
    @Default(AppConstants.defaultGridRows) int rowCount,
    @Default(true) bool rowCountAdaptive,
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default('system') String language,
    @Default(true) bool notificationsEnabled,
    @Default(false) bool onboardingCompleted,
    @Default(1) int timeFormat,
    @Default(false) bool isShortTime,
    @Default(false) bool reminderRequest,
    @Default(true) bool isReminder,
  }) = _UserSettingsEntity;
}
