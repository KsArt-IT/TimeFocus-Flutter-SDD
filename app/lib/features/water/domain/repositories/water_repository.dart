import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/water/domain/entities/day_schedule_times_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_log_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/shared/enums/day_type.dart';

abstract interface class WaterRepository {
  /// Volume drunk on [day] (UTC midnight), reactive.
  Stream<int> watchDrankToday(DateTime day);

  /// Individual drink log entries in [from, to) (schedule timeline and the
  /// history "Water" mode list), oldest first.
  Stream<List<WaterLogEntity>> watchLogPoints(DateTime from, DateTime to);

  /// A single log entry, for the water history edit screen.
  Future<Result<WaterLogEntity>> getLog(int id);

  /// Edits a single log entry's time/amount.
  Future<Result<void>> updateLog({
    required int id,
    required int volume,
    required DateTime createdAt,
  });

  Future<Result<void>> deleteLog(int id);

  Stream<WaterSettingsEntity> watchSettings();

  Future<Result<WaterSettingsEntity>> currentSettings();

  Future<Result<void>> saveSettings(WaterSettingsEntity settings);

  /// Scheduled-mode reminder times of day (minutes since midnight), sorted.
  Future<Result<List<int>>> reminderTimes();

  /// Replaces the whole set of scheduled-mode reminder times.
  Future<Result<void>> saveReminderTimes(List<int> timesMinutes);

  Stream<List<WaterQuickButtonEntity>> watchQuickButtons();

  Future<Result<void>> saveQuickButton(WaterQuickButtonEntity button);

  /// Fixes today's goal on first call of the day (data-model.md —
  /// DailyWaterGoals); returns the fixed value. Idempotent.
  Future<Result<int>> ensureDailyGoal(DateTime day);

  /// Inserts a log entry and updates lastDrankAt.
  Future<Result<void>> log(int volume, DateTime now);

  /// Highest hudPriority among currently active running activities
  /// (Sleep=1, Sport=2, Meal=3, Toilet=4), or null when nothing is running.
  Stream<int?> watchActiveHudPriority();

  /// wakeUp/sleep/meal anchors for [dayType] (used for the HUD norm-by-now
  /// interpolation and scheduled water reminders).
  Future<Result<DayScheduleTimesEntity>> dayScheduleTimes(DayType dayType);
}
