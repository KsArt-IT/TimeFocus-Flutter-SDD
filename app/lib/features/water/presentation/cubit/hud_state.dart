import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/shared/enums/hud_context_type.dart';

part 'hud_state.freezed.dart';

@freezed
sealed class HudState with _$HudState {
  const factory HudState.initial() = HudInitial;

  const factory HudState.loaded({
    required int currentMl,
    required int goalMl,
    required int expectedByNowMl,
    required HudContextType context,
    @Default(false) bool contextPulsing,
    @Default(false) bool glassBlinking,
  }) = HudLoaded;

  const factory HudState.error(AppFailure failure) = HudError;
}
