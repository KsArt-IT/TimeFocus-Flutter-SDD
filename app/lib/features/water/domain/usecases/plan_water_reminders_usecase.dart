import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/shared/enums/water_reminder_mode.dart';

part 'plan_water_reminders_usecase.freezed.dart';

/// What to (re)schedule for water reminders (contracts/notifications.md —
/// waterReminder). Building the actual NotificationDraft (title/body) is
/// left to HudCubit, which has access to l10n.
@freezed
sealed class WaterReminderPlan with _$WaterReminderPlan {
  const factory WaterReminderPlan.none() = NoWaterReminders;

  /// interval mode: a single reminder at lastDrankAt (or now) + interval.
  const factory WaterReminderPlan.single(DateTime at) = SingleWaterReminder;

  /// scheduled mode: all of the day's reminder times, minus those skipped
  /// around meals or after the sleep window (FR-024/025).
  const factory WaterReminderPlan.multiple(List<DateTime> at) = MultipleWaterReminders;
}

/// Single place computing water reminder schedule (FR-024/025). Pure: takes
/// pre-fetched schedule anchors, no I/O.
@injectable
class PlanWaterRemindersUseCase {
  WaterReminderPlan call({
    required WaterSettingsEntity settings,
    required DateTime now,
    List<int> scheduledTimesMinutes = const [],
    List<int> mealTimesMinutes = const [],
    int? sleepTimeMinutes,
  }) {
    if (!settings.remindersEnabled) return const WaterReminderPlan.none();

    switch (settings.reminderMode) {
      case WaterReminderMode.interval:
        final base = settings.lastDrankAt ?? now;
        return WaterReminderPlan.single(base.add(Duration(minutes: settings.reminderInterval)));

      case WaterReminderMode.scheduled:
        final day = DateTime(now.year, now.month, now.day);
        final times = <DateTime>[];
        for (final minutes in scheduledTimesMinutes) {
          if (sleepTimeMinutes != null && minutes >= sleepTimeMinutes) continue;
          final nearMeal = mealTimesMinutes.any(
            (meal) => (minutes - meal).abs() <= AppConstants.mealWindowMinutes,
          );
          if (nearMeal) continue;
          times.add(day.add(Duration(minutes: minutes)));
        }
        return times.isEmpty ? const WaterReminderPlan.none() : WaterReminderPlan.multiple(times);
    }
  }
}

/// Norm-by-now (data-model.md): linear interpolation of the daily goal
/// between wakeUp and sleep. Before wakeUp the norm is 0; after sleep (or
/// without a schedule) it is the full goal.
int expectedByNowMl({
  required int goalMl,
  required int nowMinutes,
  int? wakeUpMinutes,
  int? sleepMinutes,
}) {
  if (wakeUpMinutes == null || sleepMinutes == null || sleepMinutes <= wakeUpMinutes) {
    return goalMl;
  }
  if (nowMinutes <= wakeUpMinutes) return 0;
  if (nowMinutes >= sleepMinutes) return goalMl;
  final fraction = (nowMinutes - wakeUpMinutes) / (sleepMinutes - wakeUpMinutes);
  return (goalMl * fraction).round();
}

/// Recommended glasses to catch up to schedule (FR-026):
/// ceil(deficit / portion), capped at [AppConstants.maxRecommendedGlasses].
int recommendedGlasses({required int currentMl, required int expectedByNowMl}) {
  final deficit = expectedByNowMl - currentMl;
  if (deficit <= 0) return 0;
  final glasses = (deficit / AppConstants.defaultWaterPortionMl).ceil();
  return glasses > AppConstants.maxRecommendedGlasses
      ? AppConstants.maxRecommendedGlasses
      : glasses;
}
