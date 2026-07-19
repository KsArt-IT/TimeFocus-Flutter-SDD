import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/water/domain/entities/day_schedule_times_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/features/water/domain/usecases/log_water_usecase.dart';
import 'package:timefocus/features/water/domain/usecases/plan_water_reminders_usecase.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_cubit.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/drink_type.dart';
import 'package:timefocus/shared/enums/hud_context_type.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

class _MockWaterRepository extends Mock implements WaterRepository {}

class _MockLogWater extends Mock implements LogWaterUseCase {}

class _MockPlanReminders extends Mock implements PlanWaterRemindersUseCase {}

class _MockScheduler extends Mock implements NotificationScheduler {}

const drinkButton = WaterQuickButtonEntity(id: 7, volume: 150, label: DrinkType.tea, icon: 0);

/// Lets the stream subscriptions started by subscribe() deliver their first
/// (synchronous) values before the next act step runs.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  setUpAll(() {
    registerFallbackValue(NotificationType.waterReminder);
    registerFallbackValue(DayType.weekday);
    registerFallbackValue(const WaterSettingsEntity());
    registerFallbackValue(
      NotificationDraft(
        type: NotificationType.waterReminder,
        scheduledAt: DateTime(2026),
        title: '',
        body: '',
      ),
    );
  });

  late _MockWaterRepository water;
  late _MockLogWater logWater;
  late _MockPlanReminders planReminders;
  late _MockScheduler scheduler;

  void stubStreams({
    WaterSettingsEntity settings = const WaterSettingsEntity(),
    int currentMl = 0,
  }) {
    when(() => water.watchDrankToday(any())).thenAnswer((_) => Stream.value(currentMl));
    when(() => water.watchSettings()).thenAnswer((_) => Stream.value(settings));
    when(() => water.watchQuickButtons()).thenAnswer((_) => Stream.value(const [drinkButton]));
    when(() => water.watchActiveHudPriority()).thenAnswer((_) => Stream.value(null));
    when(
      () => water.ensureDailyGoal(any()),
    ).thenAnswer((_) async => const Result.success(2000));
    when(
      () => water.dayScheduleTimes(any()),
    ).thenAnswer((_) async => const Result.success(DayScheduleTimesEntity()));
    when(
      () => water.currentSettings(),
    ).thenAnswer((_) async => Result.success(settings));
  }

  setUp(() {
    water = _MockWaterRepository();
    logWater = _MockLogWater();
    planReminders = _MockPlanReminders();
    scheduler = _MockScheduler();
    stubStreams();
    when(() => logWater(any())).thenAnswer((_) async => const Result.success(null));
    when(
      () => planReminders(
        settings: any(named: 'settings'),
        now: any(named: 'now'),
      ),
    ).thenReturn(const WaterReminderPlan.none());
    when(
      () => scheduler.schedule(any()),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => scheduler.cancelByType(any()),
    ).thenAnswer((_) async => const Result.success(null));
  });

  HudCubit build() => HudCubit(water, logWater, planReminders, scheduler);

  blocTest<HudCubit, HudState>(
    "subscribe loads today's consumption against the fixed daily goal",
    build: build,
    act: (cubit) => cubit.subscribe(),
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final state = cubit.state as HudLoaded;
      expect(state.goalMl, 2000);
      expect(state.currentMl, 0);
      expect(state.context, HudContextType.empty);
      expect(state.glassBlinking, isFalse);
    },
  );

  blocTest<HudCubit, HudState>(
    'logWater delegates to LogWaterUseCase',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      await cubit.logWater(200);
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      verify(() => logWater(200)).called(1);
    },
  );

  blocTest<HudCubit, HudState>(
    'logDrink resolves the quick button volume',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      await cubit.logDrink(drinkButton.id);
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      verify(() => logWater(drinkButton.volume)).called(1);
    },
  );

  blocTest<HudCubit, HudState>(
    'interval mode replans the water reminder after a log',
    build: build,
    setUp: () {
      when(
        () => planReminders(
          settings: any(named: 'settings'),
          now: any(named: 'now'),
        ),
      ).thenReturn(WaterReminderPlan.single(DateTime(2026, 7, 18, 12)));
    },
    act: (cubit) async {
      stubStreams();
      await cubit.subscribe();
      await settle();
      await cubit.logWater(200);
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      verify(() => scheduler.cancelByType(NotificationType.waterReminder)).called(1);
      verify(() => scheduler.schedule(any())).called(1);
    },
  );

  blocTest<HudCubit, HudState>(
    'onPomodoroStateChanged(isActive: true) blinks the glass',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      cubit.onPomodoroStateChanged(isActive: true);
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      expect((cubit.state as HudLoaded).glassBlinking, isTrue);
    },
  );

  blocTest<HudCubit, HudState>(
    'onPomodoroBreakStarted surfaces the toilet context when showToiletOnBreak is set',
    build: build,
    act: (cubit) async {
      stubStreams(settings: const WaterSettingsEntity(showToiletOnBreak: true));
      await cubit.subscribe();
      await settle();
      cubit.onPomodoroBreakStarted();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      expect((cubit.state as HudLoaded).context, HudContextType.toilet);
    },
  );

  blocTest<HudCubit, HudState>(
    'onToiletTapped dismisses the toilet context until it changes',
    build: build,
    act: (cubit) async {
      stubStreams(settings: const WaterSettingsEntity(showToiletOnBreak: true));
      await cubit.subscribe();
      await settle();
      cubit
        ..onPomodoroBreakStarted()
        ..onToiletTapped();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      expect((cubit.state as HudLoaded).context, HudContextType.empty);
    },
  );
}
