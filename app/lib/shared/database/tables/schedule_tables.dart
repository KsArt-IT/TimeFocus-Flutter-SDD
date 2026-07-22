import 'package:drift/drift.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/shared/database/tables/action_tables.dart';

/// Day schedule events, separate sets for weekdays/weekend (dayType).
@DataClassName('ScheduleEventModel')
class ScheduleEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  IntColumn get mealSubtype => integer().nullable()();
  IntColumn get timeMinutes => integer()();
  IntColumn get durationMinutes =>
      integer().withDefault(const Constant(AppConstants.defaultScheduleEventDurationMin))();
  BoolColumn get isStrictly => boolean().withDefault(const Constant(false))();
  IntColumn get warningMinutes => integer().nullable()();
  IntColumn get actionId =>
      integer().nullable().references(ActionNames, #id, onDelete: KeyAction.setNull)();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get dayType => integer().withDefault(const Constant(0))();
}
