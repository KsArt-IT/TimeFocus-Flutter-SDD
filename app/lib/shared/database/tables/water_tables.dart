import 'package:drift/drift.dart';

import 'package:timefocus/core/constants/app_constants.dart';

/// Singleton (id=1) water settings.
@DataClassName('WaterSettingModel')
class WaterSettings extends Table {
  IntColumn get id => integer()();
  IntColumn get dailyWaterGoal =>
      integer().withDefault(const Constant(AppConstants.defaultDailyWaterGoalMl))();
  BoolColumn get weightMode => boolean().withDefault(const Constant(false))();
  IntColumn get weightKg => integer().withDefault(const Constant(70))();
  IntColumn get extraLoad => integer().withDefault(const Constant(0))();
  IntColumn get reminderMode => integer().withDefault(const Constant(0))();
  IntColumn get reminderInterval =>
      integer().withDefault(const Constant(AppConstants.defaultWaterReminderIntervalMin))();
  DateTimeColumn get lastDrankAt => dateTime().nullable()();
  BoolColumn get remindersEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get showToiletOnWater => boolean().withDefault(const Constant(false))();
  BoolColumn get showToiletOnBreak => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Reminder times of day (minutes from midnight) for scheduled mode.
@DataClassName('WaterReminderTimeModel')
class WaterReminderTimes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timeMinutes => integer()();
}

/// Quick drink buttons shown on long-press of the HUD glass.
@DataClassName('WaterQuickButtonModel')
class WaterQuickButtons extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get volume => integer()();
  TextColumn get label => text()();
  IntColumn get icon => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

/// Individual drink log entries.
@DataClassName('WaterLogModel')
class WaterLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get volume => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Daily goal snapshot fixed at first log / day start.
@DataClassName('DailyWaterGoalModel')
class DailyWaterGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  IntColumn get goalVolume => integer()();
}
