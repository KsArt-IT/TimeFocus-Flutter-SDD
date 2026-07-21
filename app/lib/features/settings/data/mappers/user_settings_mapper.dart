import 'package:drift/drift.dart';

import 'package:timefocus/features/settings/domain/entities/user_settings_entity.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/app_theme_mode.dart';

extension UserSettingModelMapper on UserSettingModel {
  UserSettingsEntity toEntity() => UserSettingsEntity(
    name: name,
    columnCount: columnCount,
    rowCount: rowCount,
    rowCountAdaptive: rowCountAdaptive,
    themeMode: AppThemeMode.fromIndex(themeMode),
    language: language,
    notificationsEnabled: notificationsEnabled,
    onboardingCompleted: onboardingCompleted,
    timeFormat: timeFormat,
    isShortTime: isShortTime,
    reminderRequest: reminderRequest,
    isReminder: isReminder,
  );
}

extension UserSettingsEntityMapper on UserSettingsEntity {
  UserSettingsCompanion toCompanion() => UserSettingsCompanion(
    name: Value(name),
    columnCount: Value(columnCount),
    rowCount: Value(rowCount),
    rowCountAdaptive: Value(rowCountAdaptive),
    themeMode: Value(themeMode.index),
    language: Value(language),
    notificationsEnabled: Value(notificationsEnabled),
    onboardingCompleted: Value(onboardingCompleted),
    timeFormat: Value(timeFormat),
    isShortTime: Value(isShortTime),
    reminderRequest: Value(reminderRequest),
    isReminder: Value(isReminder),
  );
}
