import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/features/schedule/domain/usecases/check_strict_events_usecase.dart';
import 'package:timefocus/features/schedule/domain/usecases/plan_day_events_usecase.dart';
import 'package:timefocus/shared/enums/meal_slot.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';

ScheduleEventEntity strictMeal(int id, int timeMinutes) => ScheduleEventEntity(
  id: id,
  type: ScheduleEventType.meal,
  mealSubtype: MealSlot.lunch,
  timeMinutes: timeMinutes,
  isStrictly: true,
);

void main() {
  group('strictEventsMissedBy (FR-032)', () {
    final now = DateTime(2026, 7, 18, 12, 45);

    test('успевает: событие после конца интервала — не в списке', () {
      final workEndAt = DateTime(2026, 7, 18, 13, 10);
      final lunch = strictMeal(1, 13 * 60 + 30); // 13:30, after 13:10
      final missed = strictEventsMissedBy(
        strictEventsToday: [lunch],
        now: now,
        workEndAt: workEndAt,
      );
      expect(missed, isEmpty);
    });

    test('не успевает: событие раньше конца интервала — в списке', () {
      final workEndAt = DateTime(2026, 7, 18, 13, 10);
      final lunch = strictMeal(1, 13 * 60); // 13:00, before 13:10
      final missed = strictEventsMissedBy(
        strictEventsToday: [lunch],
        now: now,
        workEndAt: workEndAt,
      );
      expect(missed, [lunch]);
    });

    test('совпадение с концом интервала: eventAt == workEndAt — не считается пропущенным', () {
      final workEndAt = DateTime(2026, 7, 18, 13, 10);
      final lunch = strictMeal(1, 13 * 60 + 10); // exactly 13:10
      final missed = strictEventsMissedBy(
        strictEventsToday: [lunch],
        now: now,
        workEndAt: workEndAt,
      );
      expect(missed, isEmpty);
    });

    test('несколько событий: сортировка по времени, только пропущенные', () {
      final workEndAt = DateTime(2026, 7, 18, 13, 10);
      final late = strictMeal(1, 13 * 60 + 30);
      final soon = strictMeal(2, 13 * 60);
      final missed = strictEventsMissedBy(
        strictEventsToday: [late, soon],
        now: now,
        workEndAt: workEndAt,
      );
      expect(missed, [soon]);
    });
  });

  group('PlanDayEventsUseCase', () {
    final useCase = PlanDayEventsUseCase();
    final day = DateTime(2026, 7, 18);

    test('строгая еда → mealStrict в точное время', () {
      final event = strictMeal(1, 13 * 60);
      final plans = useCase(events: [event], day: day);
      expect(plans, [
        DayEventPlan.mealStrict(event: event, at: day.add(const Duration(hours: 13))),
      ]);
    });

    test('гибкая еда → mealFlexible в точное время', () {
      final event = strictMeal(1, 13 * 60).copyWith(isStrictly: false);
      final plans = useCase(events: [event], day: day);
      expect(plans, [
        DayEventPlan.mealFlexible(event: event, at: day.add(const Duration(hours: 13))),
      ]);
    });

    test('сон → sleepReminder за 30 минут до события', () {
      final event = const ScheduleEventEntity(type: ScheduleEventType.sleep, timeMinutes: 23 * 60);
      final plans = useCase(events: [event], day: day);
      expect(plans, [
        DayEventPlan.sleepReminder(
          event: event,
          at: day.add(const Duration(hours: 22, minutes: 30)),
        ),
      ]);
    });

    test('wakeUp/work/sport/custom не планируются', () {
      final events = [
        const ScheduleEventEntity(type: ScheduleEventType.wakeUp, timeMinutes: 420),
        const ScheduleEventEntity(type: ScheduleEventType.work, timeMinutes: 540),
        const ScheduleEventEntity(type: ScheduleEventType.sport, timeMinutes: 1020),
        const ScheduleEventEntity(type: ScheduleEventType.custom, timeMinutes: 600),
      ];
      expect(useCase(events: events, day: day), isEmpty);
    });

    test('отключённое событие пропускается', () {
      final event = strictMeal(1, 13 * 60).copyWith(isEnabled: false);
      expect(useCase(events: [event], day: day), isEmpty);
    });
  });
}
