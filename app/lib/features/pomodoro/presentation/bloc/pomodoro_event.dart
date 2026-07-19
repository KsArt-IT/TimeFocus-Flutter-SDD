import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/shared/enums/pomodoro_type.dart';

part 'pomodoro_event.freezed.dart';

/// Reason a running Pomodoro work/break interval is being interrupted.
/// Mirrors TransitionEffect.pomodoroShouldStop.reason from tracker.
enum PomodoroStopReason {
  pausedByUser,
  stoppedByUser,
  pausedByOthers,
  manualBreak,
  secondPomodoro,
  strictEvent,
}

@freezed
sealed class PomodoroEvent with _$PomodoroEvent {
  /// From ActionBloc.pomodoroShouldStart (RootBlocListener) — a Pomodoro
  /// work interval must begin.
  const factory PomodoroEvent.started({
    required int actionNameId,
    required int historyId,
    required PomodoroType type,
  }) = PomodoroStarted;

  /// System timer fired for the active work session (FR-010: the only
  /// completion path).
  const factory PomodoroEvent.workIntervalFinished(int sessionId) = PomodoroWorkIntervalFinished;

  /// From ActionBloc.breakStarted (RootBlocListener) — the break activity
  /// row now exists; only meaningful while state is breakShouldStart.
  const factory PomodoroEvent.breakActivityStarted(int historyId) = PomodoroBreakActivityStarted;

  /// From ActionBloc.pomodoroShouldStop (RootBlocListener).
  const factory PomodoroEvent.interrupted(PomodoroStopReason reason) = PomodoroInterrupted;

  /// User tapped "Skip" on the active interval.
  const factory PomodoroEvent.skipped() = PomodoroSkipped;

  /// System timer fired for the active break session.
  const factory PomodoroEvent.breakFinished(int sessionId) = PomodoroBreakFinished;

  const factory PomodoroEvent.breakExtended(int minutes) = PomodoroBreakExtended;

  /// App (re)start: there is no background process, so a work interval
  /// running when the app was killed must be resumed (or, if its natural
  /// end already passed, completed) from the DB alone — same recovery path
  /// as tapping a pomodoroFinished notification from a cold start (FR-035).
  const factory PomodoroEvent.recovered() = PomodoroRecovered;
}
