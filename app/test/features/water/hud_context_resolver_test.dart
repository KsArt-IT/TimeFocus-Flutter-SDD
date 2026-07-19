import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/features/water/domain/usecases/resolve_hud_context_usecase.dart';
import 'package:timefocus/shared/enums/hud_context_type.dart';

void main() {
  group('resolveHudContext priority', () {
    test('empty when nothing is running and no triggers', () {
      final result = resolveHudContext(
        activeRunningPriority: null,
        toiletSuggested: false,
        mealTimeNow: false,
      );
      expect(result, HudContextType.empty);
    });

    test('sleep(1) from running activity', () {
      final result = resolveHudContext(
        activeRunningPriority: 1,
        toiletSuggested: false,
        mealTimeNow: false,
      );
      expect(result, HudContextType.sleep);
    });

    test('sport(2) from running activity', () {
      final result = resolveHudContext(
        activeRunningPriority: 2,
        toiletSuggested: false,
        mealTimeNow: false,
      );
      expect(result, HudContextType.sport);
    });

    test('meal(3) from running activity outranks sport', () {
      final result = resolveHudContext(
        activeRunningPriority: 2,
        toiletSuggested: false,
        mealTimeNow: true,
      );
      expect(result, HudContextType.meal);
    });

    test('mealTimeNow alone (no activity running) yields meal', () {
      final result = resolveHudContext(
        activeRunningPriority: null,
        toiletSuggested: false,
        mealTimeNow: true,
      );
      expect(result, HudContextType.meal);
    });

    test('toilet(4) outranks meal, sport and sleep', () {
      final result = resolveHudContext(
        activeRunningPriority: 3,
        toiletSuggested: true,
        mealTimeNow: true,
      );
      expect(result, HudContextType.toilet);
    });

    test('running toilet activity (priority 4) wins even without a trigger flag', () {
      final result = resolveHudContext(
        activeRunningPriority: 4,
        toiletSuggested: false,
        mealTimeNow: false,
      );
      expect(result, HudContextType.toilet);
    });
  });

  group('resolveToiletSuggested', () {
    final now = DateTime(2026, 7, 18, 10);

    test('false when both flags are off', () {
      final result = resolveToiletSuggested(
        showToiletOnWater: false,
        showToiletOnBreak: false,
        lastDrankAt: now,
        pomodoroBreakActive: true,
        now: now,
      );
      expect(result, isFalse);
    });

    test('true during a break when showToiletOnBreak is set', () {
      final result = resolveToiletSuggested(
        showToiletOnWater: false,
        showToiletOnBreak: true,
        lastDrankAt: null,
        pomodoroBreakActive: true,
        now: now,
      );
      expect(result, isTrue);
    });

    test('false when not on break, even with showToiletOnBreak set', () {
      final result = resolveToiletSuggested(
        showToiletOnWater: false,
        showToiletOnBreak: true,
        lastDrankAt: null,
        pomodoroBreakActive: false,
        now: now,
      );
      expect(result, isFalse);
    });

    test('true shortly after drinking when showToiletOnWater is set', () {
      final result = resolveToiletSuggested(
        showToiletOnWater: true,
        showToiletOnBreak: false,
        lastDrankAt: now.subtract(const Duration(minutes: 5)),
        pomodoroBreakActive: false,
        now: now,
      );
      expect(result, isTrue);
    });

    test('false once the suggestion window has elapsed', () {
      final result = resolveToiletSuggested(
        showToiletOnWater: true,
        showToiletOnBreak: false,
        lastDrankAt: now.subtract(const Duration(minutes: 30)),
        pomodoroBreakActive: false,
        now: now,
      );
      expect(result, isFalse);
    });
  });

  group('resolveMealTimeNow', () {
    test('true within the ±15 min meal window', () {
      expect(resolveMealTimeNow(13 * 60 + 10, [13 * 60]), isTrue);
      expect(resolveMealTimeNow(13 * 60 - 15, [13 * 60]), isTrue);
    });

    test('false outside the meal window', () {
      expect(resolveMealTimeNow(13 * 60 + 20, [13 * 60]), isFalse);
    });

    test('false with no meal slots', () {
      expect(resolveMealTimeNow(13 * 60, const []), isFalse);
    });
  });
}
