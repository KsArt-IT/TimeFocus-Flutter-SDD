import 'package:freezed_annotation/freezed_annotation.dart';

part 'water_quick_button_entity.freezed.dart';

/// Quick drink button shown on long-press of the HUD glass
/// (data-model.md — WaterQuickButtons). `label` is stored as free text: a
/// preset (matches a `DrinkType` name) is translated, anything else — a
/// user-entered custom name — is shown verbatim (see `localizedDrinkLabel`
/// in shared/widgets/drink_localization.dart).
@freezed
abstract class WaterQuickButtonEntity with _$WaterQuickButtonEntity {
  const factory WaterQuickButtonEntity({
    required int id,
    required int volume,
    required String label,
    required int icon,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
  }) = _WaterQuickButtonEntity;
}
