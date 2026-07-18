import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

part 'transition_effect.freezed.dart';

/// Reason for stopping/interrupting the current Pomodoro interval.
enum PomodoroStopReason {
  pausedByUser,
  stoppedByUser,
  pausedByOthers,
  manualBreak,
  secondPomodoro,
  strictEvent,
}

/// Side-effect of an action transition, consumed only by RootBlocListener
/// (contracts/blocs.md).
@freezed
sealed class TransitionEffect with _$TransitionEffect {
  const factory TransitionEffect.pomodoroShouldStart({
    required int actionNameId,
    required int historyId,
    required PomodoroType pomodoroType,
  }) = PomodoroShouldStart;

  const factory TransitionEffect.pomodoroShouldStop({required PomodoroStopReason reason}) =
      PomodoroShouldStop;

  const factory TransitionEffect.pomodoroInterrupted({
    required ActionNameEntity byAction,
    required ActionNameEntity interruptedAction,
  }) = PomodoroInterrupted;

  const factory TransitionEffect.breakStarted({required int breakActionId}) = BreakStarted;
}
