import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/schedule/domain/entities/external_event_entity.dart';
import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/features/schedule/domain/entities/timeline_item.dart';
import 'package:timefocus/shared/enums/day_type.dart';

abstract interface class ScheduleRepository {
  Stream<List<ScheduleEventEntity>> watchDay(DayType dayType);

  Future<Result<int>> create(ScheduleEventEntity e);

  Future<Result<void>> update(ScheduleEventEntity e);

  Future<Result<void>> delete(int id);

  /// Enabled strict events of today at or after [now] (FR-032 warning check).
  Future<Result<List<ScheduleEventEntity>>> strictEventsAfter(DateTime now);

  /// Tracked activity intervals of [day] as timeline rows (FR-030 — actual
  /// intervals drawn over the plan).
  Stream<List<TimelineItem>> watchActualIntervals(DateTime day);
}

/// Extension point for Phase 2 system-calendar integration (FR-033).
/// No implementation is registered in this phase.
abstract interface class CalendarDataSource {
  Future<Result<List<ExternalEventEntity>>> eventsFor(DateTime day);
}
