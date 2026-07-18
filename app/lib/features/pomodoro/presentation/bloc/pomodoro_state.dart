import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_session_entity.dart';

part 'pomodoro_state.freezed.dart';

/// suggestBreak (FR-018): the UI offers a break but nothing auto-starts.
@freezed
abstract class BreakSuggestion with _$BreakSuggestion {
  const factory BreakSuggestion({
    required int breakActionId,
    required int nextCycle,
    required bool isLong,
  }) = _BreakSuggestion;
}

@freezed
sealed class PomodoroState with _$PomodoroState {
  const factory PomodoroState.idle({BreakSuggestion? suggestion}) = PomodoroIdle;

  const factory PomodoroState.workRunning({
    required PomodoroSessionEntity session,
    required DateTime endsAt,
    required int cyclesBeforeLongBreak,
  }) = PomodoroWorkRunning;

  const factory PomodoroState.breakRunning({
    required PomodoroSessionEntity session,
    required DateTime endsAt,
    required int parentActionId,
  }) = PomodoroBreakRunning;

  /// autoStartBreak (FR-018): waiting for ActionBloc to actually start the
  /// break activity (RootBlocListener → ActionStarted(source: system)); the
  /// PomodoroSession row is only created once that succeeds
  /// (PomodoroEvent.breakActivityStarted) so it carries the real historyId.
  const factory PomodoroState.breakShouldStart({
    required int breakActionId,
    required int parentActionId,
    required int nextCycle,
    required bool isLong,
  }) = PomodoroBreakShouldStart;

  /// Break is over; work resumes automatically (RootBlocListener →
  /// ActionBloc.add(ActionStarted(parentActionId, source: system))) or by
  /// user tap on the breakFinished notification.
  const factory PomodoroState.readyToResumeWork({
    required int parentActionId,
    required int nextCycle,
  }) = PomodoroReadyToResumeWork;

  const factory PomodoroState.error(AppFailure failure) = PomodoroError;
}
