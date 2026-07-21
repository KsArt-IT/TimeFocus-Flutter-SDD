import 'package:drift/drift.dart';

import 'package:timefocus/features/water/domain/entities/water_log_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/drink_type.dart';
import 'package:timefocus/shared/enums/water_reminder_mode.dart';

extension WaterSettingModelMapper on WaterSettingModel {
  WaterSettingsEntity toEntity() => WaterSettingsEntity(
    dailyWaterGoal: dailyWaterGoal,
    weightMode: weightMode,
    weightKg: weightKg,
    extraLoad: extraLoad,
    reminderMode: WaterReminderMode.fromIndex(reminderMode),
    reminderInterval: reminderInterval,
    lastDrankAt: lastDrankAt,
    remindersEnabled: remindersEnabled,
    showToiletOnWater: showToiletOnWater,
    showToiletOnBreak: showToiletOnBreak,
  );
}

extension WaterSettingsEntityMapper on WaterSettingsEntity {
  WaterSettingsCompanion toCompanion() => WaterSettingsCompanion(
    dailyWaterGoal: Value(dailyWaterGoal),
    weightMode: Value(weightMode),
    weightKg: Value(weightKg),
    extraLoad: Value(extraLoad),
    reminderMode: Value(reminderMode.index),
    reminderInterval: Value(reminderInterval),
    lastDrankAt: Value(lastDrankAt),
    remindersEnabled: Value(remindersEnabled),
    showToiletOnWater: Value(showToiletOnWater),
    showToiletOnBreak: Value(showToiletOnBreak),
  );
}

extension WaterLogModelMapper on WaterLogModel {
  WaterLogEntity toEntity() => WaterLogEntity(id: id, volume: volume, createdAt: createdAt);
}

extension WaterQuickButtonModelMapper on WaterQuickButtonModel {
  WaterQuickButtonEntity toEntity() => WaterQuickButtonEntity(
    id: id,
    volume: volume,
    label: DrinkType.values.firstWhere(
      (d) => d.name == label,
      orElse: () => DrinkType.water,
    ),
    icon: icon,
    sortOrder: sortOrder,
    isActive: isActive,
  );
}

extension WaterQuickButtonEntityMapper on WaterQuickButtonEntity {
  WaterQuickButtonsCompanion toCompanion() => WaterQuickButtonsCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    volume: Value(volume),
    label: Value(label.name),
    icon: Value(icon),
    sortOrder: Value(sortOrder),
    isActive: Value(isActive),
  );
}
