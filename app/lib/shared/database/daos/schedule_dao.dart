import 'package:drift/drift.dart';

import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/tables/schedule_tables.dart';

part 'schedule_dao.g.dart';

@DriftAccessor(tables: [ScheduleEvents])
class ScheduleDao extends DatabaseAccessor<AppDatabase> with _$ScheduleDaoMixin {
  ScheduleDao(super.attachedDatabase);

  Stream<List<ScheduleEventModel>> watchDay(int dayType) =>
      (select(scheduleEvents)
            ..where((t) => t.dayType.equals(dayType))
            ..orderBy([(t) => OrderingTerm.asc(t.timeMinutes)]))
          .watch();

  Future<List<ScheduleEventModel>> eventsForDay(int dayType) =>
      (select(scheduleEvents)
            ..where((t) => t.dayType.equals(dayType) & t.isEnabled.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.timeMinutes)]))
          .get();

  Future<ScheduleEventModel?> getById(int id) =>
      (select(scheduleEvents)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertEvent(ScheduleEventsCompanion companion) =>
      into(scheduleEvents).insert(companion);

  Future<bool> updateEvent(ScheduleEventsCompanion companion) =>
      update(scheduleEvents).replace(companion);

  Future<void> deleteEvent(int id) => (delete(scheduleEvents)..where((t) => t.id.equals(id))).go();

  /// Enabled strict events of [dayType] at or after [nowMinutes].
  Future<List<ScheduleEventModel>> strictEventsAfter(int dayType, int nowMinutes) =>
      (select(scheduleEvents)
            ..where(
              (t) =>
                  t.dayType.equals(dayType) &
                  t.isStrictly.equals(true) &
                  t.isEnabled.equals(true) &
                  t.timeMinutes.isBiggerOrEqualValue(nowMinutes),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.timeMinutes)]))
          .get();
}
