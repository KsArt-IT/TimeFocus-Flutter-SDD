import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/features/tracker/domain/usecases/start_action_usecase.dart';

part 'action_event.freezed.dart';

@freezed
sealed class ActionEvent with _$ActionEvent {
  /// Subscribes to running activities + grid streams.
  const factory ActionEvent.subscribed() = ActionsSubscribed;

  /// Opens a group in-place (null — back to root, FR-007).
  const factory ActionEvent.groupOpened(int? groupId) = ActionGroupOpened;

  const factory ActionEvent.started(
    int actionNameId, {
    @Default(ActionStartSource.user) ActionStartSource source,
  }) = ActionStarted;

  /// Confirmation of interrupting the current Pomodoro (FR-011).
  const factory ActionEvent.startConfirmed(int actionNameId) = ActionStartConfirmed;

  /// Refusal — nothing changes (FR-011).
  const factory ActionEvent.startCancelled() = ActionStartCancelled;

  const factory ActionEvent.paused(int runningId) = ActionPaused;

  const factory ActionEvent.resumed(int actionNameId) = ActionResumed;

  const factory ActionEvent.stopped(int runningId) = ActionStopped;

  /// Effect was consumed by RootBlocListener.
  const factory ActionEvent.transitionHandled() = ActionTransitionHandled;

  /// Internal: stream data updated (running/grid caches changed).
  const factory ActionEvent.dataChanged() = ActionDataChanged;
}
