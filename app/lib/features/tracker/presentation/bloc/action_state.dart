import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/transition_effect.dart';

part 'action_state.freezed.dart';

@freezed
sealed class ActionState with _$ActionState {
  const factory ActionState.initial() = ActionInitial;

  const factory ActionState.loading() = ActionLoading;

  const factory ActionState.loaded({
    @Default(<RunningWithNameEntity>[]) List<RunningWithNameEntity> running,
    @Default(<ActionNameEntity>[]) List<ActionNameEntity> grid,
    int? currentGroupId,
    ActionNameEntity? pendingConfirmation,
    TransitionEffect? lastTransition,
    @Default(<int, int>{}) Map<int, int> todayTotals,
  }) = ActionLoaded;

  const factory ActionState.error(AppFailure failure) = ActionError;
}
