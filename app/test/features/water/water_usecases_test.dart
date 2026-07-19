import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/features/water/domain/usecases/log_water_usecase.dart';
import 'package:timefocus/features/water/domain/usecases/plan_water_reminders_usecase.dart';
import 'package:timefocus/shared/enums/water_reminder_mode.dart';

class _MockWaterRepository extends Mock implements WaterRepository {}

void main() {
  group('LogWaterUseCase', () {
    late _MockWaterRepository repository;
    late LogWaterUseCase useCase;
    final now = DateTime(2026, 7, 18, 10, 30);

    setUp(() {
      repository = _MockWaterRepository();
      useCase = LogWaterUseCase(repository);
    });

    test('fixes the daily goal then logs the drink', () async {
      when(
        () => repository.ensureDailyGoal(any()),
      ).thenAnswer((_) async => const Result.success(2000));
      when(
        () => repository.log(any(), any()),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await useCase(200, now: now);

      expect(result.isSuccess, isTrue);
      verify(() => repository.ensureDailyGoal(DateTime.utc(2026, 7, 18))).called(1);
      verify(() => repository.log(200, now)).called(1);
    });

    test('stops and propagates the failure when fixing the goal fails', () async {
      when(
        () => repository.ensureDailyGoal(any()),
      ).thenAnswer((_) async => const Result.failure(DatabaseFailure('db error')));

      final result = await useCase(200, now: now);

      expect(result.isFailure, isTrue);
      verifyNever(() => repository.log(any(), any()));
    });
  });

  group('PlanWaterRemindersUseCase', () {
    final useCase = PlanWaterRemindersUseCase();
    final now = DateTime(2026, 7, 18, 10);

    test('none when reminders are disabled', () {
      final plan = useCase(
        settings: const WaterSettingsEntity(remindersEnabled: false),
        now: now,
      );
      expect(plan, const WaterReminderPlan.none());
    });

    test('interval mode schedules lastDrankAt + interval', () {
      final lastDrankAt = now.subtract(const Duration(minutes: 30));
      final plan = useCase(
        settings: WaterSettingsEntity(reminderInterval: 45, lastDrankAt: lastDrankAt),
        now: now,
      );
      expect(plan, isA<SingleWaterReminder>());
      expect((plan as SingleWaterReminder).at, lastDrankAt.add(const Duration(minutes: 45)));
    });

    test('interval mode falls back to now when never drunk', () {
      final plan = useCase(
        settings: const WaterSettingsEntity(reminderInterval: 60),
        now: now,
      );
      expect((plan as SingleWaterReminder).at, now.add(const Duration(minutes: 60)));
    });

    test('scheduled mode skips times within ±15 min of a meal', () {
      final plan = useCase(
        settings: const WaterSettingsEntity(reminderMode: WaterReminderMode.scheduled),
        now: now,
        scheduledTimesMinutes: [8 * 60, 13 * 60 + 10, 18 * 60],
        mealTimesMinutes: [13 * 60],
      );
      final times = (plan as MultipleWaterReminders).at;
      expect(times, hasLength(2));
      expect(
        times,
        containsAll([
          DateTime(2026, 7, 18).add(const Duration(hours: 8)),
          DateTime(2026, 7, 18).add(const Duration(hours: 18)),
        ]),
      );
    });

    test('scheduled mode discards times at/after the sleep window', () {
      final plan = useCase(
        settings: const WaterSettingsEntity(reminderMode: WaterReminderMode.scheduled),
        now: now,
        scheduledTimesMinutes: [10 * 60, 23 * 60 + 30],
        sleepTimeMinutes: 23 * 60,
      );
      final times = (plan as MultipleWaterReminders).at;
      expect(times, hasLength(1));
    });

    test('scheduled mode with no surviving times yields none', () {
      final plan = useCase(
        settings: const WaterSettingsEntity(reminderMode: WaterReminderMode.scheduled),
        now: now,
        scheduledTimesMinutes: [23 * 60 + 30],
        sleepTimeMinutes: 23 * 60,
      );
      expect(plan, const WaterReminderPlan.none());
    });
  });

  group('recommendedGlasses (FR-026)', () {
    test('zero when at or ahead of schedule', () {
      expect(recommendedGlasses(currentMl: 1000, expectedByNowMl: 800), 0);
    });

    test('ceils the deficit to whole glasses', () {
      expect(recommendedGlasses(currentMl: 100, expectedByNowMl: 450), 2);
    });

    test('caps at maxRecommendedGlasses', () {
      expect(recommendedGlasses(currentMl: 0, expectedByNowMl: 2000), 4);
    });
  });

  group('expectedByNowMl', () {
    test('interpolates linearly between wakeUp and sleep', () {
      final result = expectedByNowMl(
        goalMl: 2000,
        nowMinutes: 15 * 60,
        wakeUpMinutes: 7 * 60,
        sleepMinutes: 23 * 60,
      );
      // (15:00 - 07:00) / (23:00 - 07:00) = 0.5 → 1000ml
      expect(result, 1000);
    });

    test('zero before wakeUp, full goal after sleep', () {
      expect(
        expectedByNowMl(
          goalMl: 2000,
          nowMinutes: 6 * 60,
          wakeUpMinutes: 7 * 60,
          sleepMinutes: 23 * 60,
        ),
        0,
      );
      expect(
        expectedByNowMl(
          goalMl: 2000,
          nowMinutes: 23 * 60 + 30,
          wakeUpMinutes: 7 * 60,
          sleepMinutes: 23 * 60,
        ),
        2000,
      );
    });

    test('falls back to the full goal without a schedule', () {
      expect(expectedByNowMl(goalMl: 2000, nowMinutes: 12 * 60), 2000);
    });
  });
}
