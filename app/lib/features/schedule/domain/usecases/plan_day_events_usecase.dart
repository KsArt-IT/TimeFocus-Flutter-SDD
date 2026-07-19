import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';

part 'plan_day_events_usecase.freezed.dart';

/// What to schedule for one day event (contracts/notifications.md). Building
/// the actual NotificationDraft (title/body) is left to the caller, which
/// has access to l10n.
@freezed
sealed class DayEventPlan with _$DayEventPlan {
  /// mealFlexible: notification fires at eventTime; if a Pomodoro is active
  /// when it fires, NotificationBloc defers it until the break (FR-031,
  /// implemented in US5's deferred queue — not this phase's concern).
  const factory DayEventPlan.mealFlexible({
    required ScheduleEventEntity event,
    required DateTime at,
  }) = MealFlexiblePlan;

  /// mealStrict: notification at the exact time; RootBlocListener/PomodoroBloc
  /// force-interrupts a running work interval independently (FR-031, see
  /// CheckStrictEventsUseCase).
  const factory DayEventPlan.mealStrict({
    required ScheduleEventEntity event,
    required DateTime at,
  }) = MealStrictPlan;

  /// sleepReminder: fires [AppConstants.sleepReminderMinutes] before sleep.
  const factory DayEventPlan.sleepReminder({
    required ScheduleEventEntity event,
    required DateTime at,
  }) = SleepReminderPlan;
}

/// Single place turning today's enabled events into a notification plan
/// (FR-031). Pure: no I/O, no NotificationScheduler calls.
@injectable
class PlanDayEventsUseCase {
  List<DayEventPlan> call({required List<ScheduleEventEntity> events, required DateTime day}) {
    final plans = <DayEventPlan>[];
    for (final e in events) {
      if (!e.isEnabled) continue;
      final eventAt = day.add(Duration(minutes: e.timeMinutes));
      switch (e.type) {
        case ScheduleEventType.meal:
          plans.add(
            e.isStrictly
                ? DayEventPlan.mealStrict(event: e, at: eventAt)
                : DayEventPlan.mealFlexible(event: e, at: eventAt),
          );
        case ScheduleEventType.sleep:
          plans.add(
            DayEventPlan.sleepReminder(
              event: e,
              at: eventAt.subtract(const Duration(minutes: AppConstants.sleepReminderMinutes)),
            ),
          );
        case ScheduleEventType.wakeUp:
        case ScheduleEventType.work:
        case ScheduleEventType.sport:
        case ScheduleEventType.custom:
          break;
      }
    }
    return plans;
  }
}
