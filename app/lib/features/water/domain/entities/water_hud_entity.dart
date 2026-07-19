import 'package:freezed_annotation/freezed_annotation.dart';

part 'water_hud_entity.freezed.dart';

/// Snapshot of today's water consumption for the HUD panel
/// (contracts/blocs.md — HudCubit.loaded).
@freezed
abstract class WaterHudEntity with _$WaterHudEntity {
  const factory WaterHudEntity({
    required int currentMl,
    required int goalMl,
    required int expectedByNowMl,
  }) = _WaterHudEntity;
}
