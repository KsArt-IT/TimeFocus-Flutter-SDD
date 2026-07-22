import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';

part 'water_settings_state.freezed.dart';

@freezed
sealed class WaterSettingsState with _$WaterSettingsState {
  const factory WaterSettingsState.loading() = WaterSettingsLoading;

  const factory WaterSettingsState.loaded({
    required WaterSettingsEntity settings,
    required List<int> reminderTimes,
    @Default(<WaterQuickButtonEntity>[]) List<WaterQuickButtonEntity> quickButtons,
  }) = WaterSettingsLoaded;

  const factory WaterSettingsState.error(AppFailure failure) = WaterSettingsError;
}
