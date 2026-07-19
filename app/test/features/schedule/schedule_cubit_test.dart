import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/features/schedule/domain/entities/timeline_item.dart';
import 'package:timefocus/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:timefocus/features/schedule/domain/usecases/plan_day_events_usecase.dart';
import 'package:timefocus/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/notification_type.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockWaterRepository extends Mock implements WaterRepository {}

class _MockPlanDayEvents extends Mock implements PlanDayEventsUseCase {}

class _MockScheduler extends Mock implements NotificationScheduler {}

const lunch = ScheduleEventEntity(
  id: 1,
  type: ScheduleEventType.meal,
  timeMinutes: 780,
  isStrictly: true,
);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  setUpAll(() {
    registerFallbackValue(DayType.weekday);
    registerFallbackValue(
      const ScheduleEventEntity(type: ScheduleEventType.custom, timeMinutes: 0),
    );
    registerFallbackValue(
      NotificationDraft(
        type: NotificationType.mealStrict,
        scheduledAt: DateTime(2026),
        title: '',
        body: '',
      ),
    );
  });

  late _MockScheduleRepository schedule;
  late _MockWaterRepository water;
  late _MockPlanDayEvents planDayEvents;
  late _MockScheduler scheduler;

  void stubStreams({List<ScheduleEventEntity> events = const []}) {
    when(() => schedule.watchDay(any())).thenAnswer((_) => Stream.value(events));
    when(() => schedule.watchActualIntervals(any())).thenAnswer((_) => Stream.value(const []));
    when(() => water.watchLogPoints(any())).thenAnswer((_) => Stream.value(const []));
  }

  setUp(() {
    schedule = _MockScheduleRepository();
    water = _MockWaterRepository();
    planDayEvents = _MockPlanDayEvents();
    scheduler = _MockScheduler();
    stubStreams();
    when(
      () => planDayEvents(
        events: any(named: 'events'),
        day: any(named: 'day'),
      ),
    ).thenReturn([]);
    when(() => scheduler.schedule(any())).thenAnswer((_) async => const Result.success(null));
    when(() => schedule.create(any())).thenAnswer((_) async => const Result.success(1));
    when(() => schedule.update(any())).thenAnswer((_) async => const Result.success(null));
    when(() => schedule.delete(any())).thenAnswer((_) async => const Result.success(null));
  });

  ScheduleCubit build() => ScheduleCubit(schedule, water, planDayEvents, scheduler);

  blocTest<ScheduleCubit, ScheduleState>(
    'subscribe merges plan events into the timeline',
    build: build,
    setUp: () => stubStreams(events: const [lunch]),
    act: (cubit) => cubit.subscribe(),
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final state = cubit.state as ScheduleLoaded;
      expect(state.timeline, hasLength(1));
      expect(state.timeline.single.kind, TimelineItemKind.planned);
      expect(state.timeline.single.event, lunch);
    },
  );

  blocTest<ScheduleCubit, ScheduleState>(
    'schedules a notification per DayEventPlan when the plan changes',
    build: build,
    setUp: () {
      stubStreams(events: const [lunch]);
      when(
        () => planDayEvents(
          events: any(named: 'events'),
          day: any(named: 'day'),
        ),
      ).thenReturn([
        DayEventPlan.mealStrict(event: lunch, at: DateTime(2026, 7, 18, 13)),
      ]);
    },
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      verify(() => scheduler.schedule(any())).called(1);
    },
  );

  blocTest<ScheduleCubit, ScheduleState>(
    "createEvent delegates to ScheduleRepository with today's dayType",
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      await cubit.createEvent(lunch);
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      verify(() => schedule.create(any())).called(1);
    },
  );

  blocTest<ScheduleCubit, ScheduleState>(
    'deleteEvent delegates to ScheduleRepository',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      await cubit.deleteEvent(lunch.id);
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      verify(() => schedule.delete(lunch.id)).called(1);
    },
  );
}
