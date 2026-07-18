import 'package:drift/drift.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/shared/database/tables/action_tables.dart';

/// Versioned Pomodoro settings: every change inserts a new row.
@DataClassName('PomodoroSettingModel')
class PomodoroSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shortWorkTime =>
      integer().withDefault(const Constant(AppConstants.pomodoroShortWorkSec))();
  IntColumn get normalWorkTime =>
      integer().withDefault(const Constant(AppConstants.pomodoroNormalWorkSec))();
  IntColumn get longWorkTime =>
      integer().withDefault(const Constant(AppConstants.pomodoroLongWorkSec))();
  IntColumn get shortBreakTime =>
      integer().withDefault(const Constant(AppConstants.pomodoroShortBreakSec))();
  IntColumn get longBreakTime =>
      integer().withDefault(const Constant(AppConstants.pomodoroLongBreakSec))();
  IntColumn get cyclesBeforeLongBreak =>
      integer().withDefault(const Constant(AppConstants.defaultCyclesBeforeLongBreak))();
  BoolColumn get escalateIntervals => boolean().withDefault(const Constant(false))();
  IntColumn get afterAction => integer().withDefault(const Constant(0))();
  BoolColumn get soundEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get vibrationEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get notificationEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Pomodoro work/break interval records referencing a settings snapshot.
@DataClassName('PomodoroSessionModel')
class PomodoroSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get actionNameId => integer().nullable().references(ActionNames, #id)();
  IntColumn get actionHistoryId => integer().nullable().references(ActionHistories, #id)();
  IntColumn get settingsId => integer().references(PomodoroSettings, #id)();
  IntColumn get type => integer()();
  IntColumn get plannedTime => integer()();
  IntColumn get actualTime => integer().withDefault(const Constant(0))();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get cycleNumber => integer().withDefault(const Constant(1))();
}
