import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/schedule/data/mappers/schedule_mappers.dart';
import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/features/schedule/domain/entities/timeline_item.dart';
import 'package:timefocus/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/day_type.dart';

@LazySingleton(as: ScheduleRepository)
class ScheduleRepositoryImpl with SafeCallMixin implements ScheduleRepository {
  ScheduleRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ScheduleEventEntity>> watchDay(DayType dayType) => _db.scheduleDao
      .watchDay(dayType.index)
      .map((rows) => rows.map((r) => r.toEntity(dayType)).toList());

  @override
  Future<Result<int>> create(ScheduleEventEntity e) => safeCall(
    () => _db.scheduleDao.insertEvent(e.toCompanion(includeId: false)),
  );

  @override
  Future<Result<void>> update(ScheduleEventEntity e) => voidSafeCall(
    () => _db.scheduleDao.updateEvent(e.toCompanion()),
  );

  @override
  Future<Result<void>> delete(int id) => voidSafeCall(() => _db.scheduleDao.deleteEvent(id));

  @override
  Future<Result<List<ScheduleEventEntity>>> strictEventsAfter(DateTime now) => safeCall(() async {
    final dayType = DayType.fromDate(now);
    final nowMinutes = now.hour * 60 + now.minute;
    final rows = await _db.scheduleDao.strictEventsAfter(dayType.index, nowMinutes);
    return rows.map((r) => r.toEntity(dayType)).toList();
  });

  @override
  Stream<List<TimelineItem>> watchActualIntervals(DateTime day) => _db.historyDao
      .watchIntervals(day, day.add(const Duration(days: 1)))
      .map(
        (rows) => rows
            .map(
              (r) => TimelineItem(
                kind: TimelineItemKind.actual,
                start: r.interval.startedAt,
                end: r.interval.finishedAt,
                color: r.name.color,
                actionName: r.name.name,
                isSystemAction: r.name.isSystem,
              ),
            )
            .toList(),
      );
}
