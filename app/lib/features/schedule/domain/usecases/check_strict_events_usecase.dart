import 'package:injectable/injectable.dart';

import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/features/schedule/domain/repositories/schedule_repository.dart';

/// Pure (FR-032): of today's strict events at/after [now], which ones a
/// Pomodoro work interval ending at [workEndAt] will NOT reach in time
/// (`eventTime < workEndAt` — strict, so an event landing exactly on the
/// interval's natural end does not count). Sorted soonest first; the first
/// entry is the point PomodoroBloc must force-interrupt at.
List<ScheduleEventEntity> strictEventsMissedBy({
  required List<ScheduleEventEntity> strictEventsToday,
  required DateTime now,
  required DateTime workEndAt,
}) {
  final day = DateTime(now.year, now.month, now.day);
  final missed = strictEventsToday.where((e) {
    final eventAt = day.add(Duration(minutes: e.timeMinutes));
    return eventAt.isBefore(workEndAt);
  }).toList()..sort((a, b) => a.timeMinutes.compareTo(b.timeMinutes));
  return missed;
}

/// Fetches today's strict events and applies [strictEventsMissedBy]
/// (called from PomodoroBloc at every work-interval start, FR-032).
@injectable
class CheckStrictEventsUseCase {
  CheckStrictEventsUseCase(this._schedule);

  final ScheduleRepository _schedule;

  Future<Result<List<ScheduleEventEntity>>> call({
    required DateTime now,
    required DateTime workEndAt,
  }) async {
    final result = await _schedule.strictEventsAfter(now);
    return result.map(
      success: (events) => Result.success(
        strictEventsMissedBy(strictEventsToday: events, now: now, workEndAt: workEndAt),
      ),
      failure: Result.failure,
    );
  }
}
