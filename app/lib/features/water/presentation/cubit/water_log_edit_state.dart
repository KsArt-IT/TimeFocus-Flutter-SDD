import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/features/water/domain/entities/water_log_entity.dart';

part 'water_log_edit_state.freezed.dart';

@freezed
sealed class WaterLogEditState with _$WaterLogEditState {
  const factory WaterLogEditState.loading() = WaterLogEditLoading;

  const factory WaterLogEditState.loaded({required WaterLogEntity log}) = WaterLogEditLoaded;

  const factory WaterLogEditState.error(AppFailure failure) = WaterLogEditError;
}
