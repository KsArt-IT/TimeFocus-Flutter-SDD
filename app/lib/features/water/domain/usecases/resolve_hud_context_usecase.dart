import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/shared/enums/hud_context_type.dart';

/// Single place deciding the HUD contextual icon (contracts/blocs.md —
/// HudContextResolver). Priority: toilet(4) > meal(3) > sport(2) > sleep(1)
/// > empty(0). Sport/sleep come from the currently running system activity's
/// hudPriority (same column already encodes this exact ranking); meal-by-time
/// and toilet are computed separately since they can apply without an
/// activity being started.
HudContextType resolveHudContext({
  required int? activeRunningPriority,
  required bool toiletSuggested,
  required bool mealTimeNow,
}) {
  var priority = activeRunningPriority ?? 0;
  if (toiletSuggested && priority < HudContextType.toilet.priority) {
    priority = HudContextType.toilet.priority;
  }
  if (mealTimeNow && priority < HudContextType.meal.priority) {
    priority = HudContextType.meal.priority;
  }
  return HudContextType.fromIndex(priority);
}

/// Toilet suggested when the user just drank (showToiletOnWater, within
/// [AppConstants.toiletSuggestWindowMinutes]) or a Pomodoro break is running
/// (showToiletOnBreak, FR-010b — showing the icon never interrupts the break).
bool resolveToiletSuggested({
  required bool showToiletOnWater,
  required bool showToiletOnBreak,
  required DateTime? lastDrankAt,
  required bool pomodoroBreakActive,
  required DateTime now,
}) {
  if (showToiletOnBreak && pomodoroBreakActive) return true;
  if (showToiletOnWater && lastDrankAt != null) {
    final sinceMinutes = now.difference(lastDrankAt).inMinutes;
    if (sinceMinutes >= 0 && sinceMinutes < AppConstants.toiletSuggestWindowMinutes) return true;
  }
  return false;
}

/// True when [nowMinutes] falls within ±[AppConstants.mealWindowMinutes] of
/// any scheduled meal time — used both to skip water reminders around meals
/// (FR-024) and to surface the HUD meal icon by time of day.
bool resolveMealTimeNow(int nowMinutes, List<int> mealTimesMinutes) => mealTimesMinutes.any(
  (m) => (nowMinutes - m).abs() <= AppConstants.mealWindowMinutes,
);
