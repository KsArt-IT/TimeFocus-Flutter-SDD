import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/shared/enums/water_reminder_mode.dart';

part 'water_settings_entity.freezed.dart';

/// Singleton water settings (data-model.md — WaterSettings).
@freezed
abstract class WaterSettingsEntity with _$WaterSettingsEntity {
  const WaterSettingsEntity._();

  const factory WaterSettingsEntity({
    @Default(AppConstants.defaultDailyWaterGoalMl) int dailyWaterGoal,
    @Default(false) bool weightMode,
    @Default(70) int weightKg,
    @Default(0) int extraLoad,
    @Default(WaterReminderMode.interval) WaterReminderMode reminderMode,
    @Default(AppConstants.defaultWaterReminderIntervalMin) int reminderInterval,
    DateTime? lastDrankAt,
    @Default(true) bool remindersEnabled,
    @Default(false) bool showToiletOnWater,
    @Default(false) bool showToiletOnBreak,
  }) = _WaterSettingsEntity;

  /// Daily goal (data-model.md): by weight or manual, plus extra load.
  int get computedGoalMl =>
      (weightMode ? weightKg * AppConstants.waterMlPerKg : dailyWaterGoal) + extraLoad;
}
