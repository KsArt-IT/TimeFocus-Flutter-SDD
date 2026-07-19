import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/water/domain/entities/day_schedule_times_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/shared/enums/day_type.dart';

abstract interface class WaterRepository {
  /// Volume drunk on [day] (UTC midnight), reactive.
  Stream<int> watchDrankToday(DateTime day);

  /// Individual drink log points in [day] (for the schedule timeline).
  Stream<List<({DateTime createdAt, int volume})>> watchLogPoints(DateTime day);

  Stream<WaterSettingsEntity> watchSettings();

  Future<Result<WaterSettingsEntity>> currentSettings();

  Future<Result<void>> saveSettings(WaterSettingsEntity settings);

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
