import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_session_entity.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_repository.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_settings_repository.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/shared/enums/pomodoro_after_action.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';

part 'finish_pomodoro_interval_usecase.freezed.dart';

/// What PomodoroBloc must do next, decided from PomodoroSettings.afterAction
/// (FR-018).
@freezed
sealed class FinishPomodoroOutcome with _$FinishPomodoroOutcome {
  /// doNothing, or autoStartBreak/suggestBreak without a configured break
  /// activity — cycle stops here; [nextCycle] is what the next manual start
  /// must resume at (FR-014).
  const factory FinishPomodoroOutcome.idle({required int nextCycle}) = FinishIdle;

  /// suggestBreak: UI offers a break, nothing starts automatically.
  const factory FinishPomodoroOutcome.breakSuggested({
    required int breakActionId,
    required int nextCycle,
    required bool isLong,
  }) = FinishBreakSuggested;

  /// autoStartBreak: PomodoroBloc must ask ActionBloc to start the break
  /// activity (source: system — does not count as an interruption).
  const factory FinishPomodoroOutcome.startBreak({
    required int breakActionId,
    required int nextCycle,
    required bool isLong,
  }) = FinishStartBreak;

  /// repeatSame/autoStartWork: a new work session already started in place —
  /// no underlying activity switch, work keeps running uninterrupted.
  const factory FinishPomodoroOutcome.workRestarted(PomodoroSessionEntity session) =
      FinishWorkRestarted;
}

/// Single place deciding what follows a completed Pomodoro work interval
/// (FR-014, FR-018). Completion is only ever system-triggered; interrupted
/// intervals never reach this use case and don't advance the cycle.
@injectable
class FinishPomodoroIntervalUseCase {
  FinishPomodoroIntervalUseCase(this._sessions, this._settings);

  final PomodoroRepository _sessions;
  final PomodoroSettingsRepository _settings;

  Future<Result<FinishPomodoroOutcome>> call({
    required PomodoroSessionEntity workSession,
    required ActionNameEntity workAction,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();

    final finishResult = await _sessions.finish(workSession.id, PomodoroStatus.completed, at);
    if (finishResult.isFailure) return Result.failure(finishResult.errorOrNull!);

    final settingsResult = await _settings.current();
    final settings = settingsResult.valueOrNull;
    if (settings == null) {
      return Result.failure(settingsResult.errorOrNull ?? const UnknownFailure('no settings'));
    }

    // FR-014: a completed interval advances the cycle; the long break fires
    // once cyclesBeforeLongBreak is reached, then the counter resets to 1.
    final isLongBreak = workSession.cycleNumber >= settings.cyclesBeforeLongBreak;
    final nextCycle = isLongBreak ? 1 : workSession.cycleNumber + 1;
    final breakActionId = workAction.breakActionId;
    final historyId = workSession.actionHistoryId ?? 0;

    switch (settings.afterAction) {
      case PomodoroAfterAction.doNothing:
        return Result.success(FinishPomodoroOutcome.idle(nextCycle: nextCycle));

      case PomodoroAfterAction.autoStartBreak:
        if (breakActionId == null) {
          return Result.success(FinishPomodoroOutcome.idle(nextCycle: nextCycle));
        }
        return Result.success(
          FinishPomodoroOutcome.startBreak(
            breakActionId: breakActionId,
            nextCycle: nextCycle,
            isLong: isLongBreak,
          ),
        );

      case PomodoroAfterAction.suggestBreak:
        if (breakActionId == null) {
          return Result.success(FinishPomodoroOutcome.idle(nextCycle: nextCycle));
        }
        return Result.success(
          FinishPomodoroOutcome.breakSuggested(
            breakActionId: breakActionId,
            nextCycle: nextCycle,
            isLong: isLongBreak,
          ),
        );

      case PomodoroAfterAction.repeatSame:
        // Repeats the exact interval that just finished — cycle number
        // is not consumed since no break was taken.
        final result = await _sessions.startSession(
          actionNameId: workAction.id,
          historyId: historyId,
          type: workSession.type,
          cycleNumber: workSession.cycleNumber,
          isBreak: false,
        );
        return result.map(
          success: (s) => Result.success(FinishPomodoroOutcome.workRestarted(s)),
          failure: Result.failure,
        );

      case PomodoroAfterAction.autoStartWork:
        // Skips the break but still advances the cycle as if it happened.
        final result = await _sessions.startSession(
          actionNameId: workAction.id,
          historyId: historyId,
          type: workSession.type,
          cycleNumber: nextCycle,
          isBreak: false,
        );
        return result.map(
          success: (s) => Result.success(FinishPomodoroOutcome.workRestarted(s)),
          failure: Result.failure,
        );
    }
  }
}
