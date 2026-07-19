import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/shared/enums/drink_type.dart';

part 'water_quick_button_entity.freezed.dart';

/// Quick drink button shown on long-press of the HUD glass
/// (data-model.md — WaterQuickButtons).
@freezed
abstract class WaterQuickButtonEntity with _$WaterQuickButtonEntity {
  const factory WaterQuickButtonEntity({
    required int id,
    required int volume,
    required DrinkType label,
    required int icon,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
  }) = _WaterQuickButtonEntity;
}
