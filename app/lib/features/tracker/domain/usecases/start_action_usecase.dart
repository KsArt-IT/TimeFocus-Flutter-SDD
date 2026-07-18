import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/transition_effect.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_running_repository.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/action_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

part 'start_action_usecase.freezed.dart';

/// Who initiated the transition. System transitions (e.g. break→work resume
/// after PomodoroWorkIntervalFinished) never interrupt the Pomodoro.
enum ActionStartSource { user, system }

@freezed
sealed class StartActionOutcome with _$StartActionOutcome {
  /// FR-011: a second Pomodoro requires explicit confirmation.
  const factory StartActionOutcome.needsConfirmation(ActionNameEntity action) =
      StartNeedsConfirmation;

  const factory StartActionOutcome.started({
    required int runningId,
    required List<TransitionEffect> effects,
  }) = StartStarted;

  /// Action was already active — nothing changed.
  const factory StartActionOutcome.noop() = StartNoop;
}

/// The single place defining the activity transition matrix
/// (FR-010/010a/010b/011, constitution principle V).
@injectable
class StartActionUseCase {
  StartActionUseCase(this._actions, this._runnings);

  final ActionNameRepository _actions;
  final ActionRunningRepository _runnings;

  /// The single definition point for "does starting [action] interrupt the
  /// current Pomodoro work interval".
  bool shouldInterruptPomodoro(ActionNameEntity action, {required bool isSystemTransition}) =>
      !isSystemTransition &&
      (action.mode == ActionMode.pomodoro ||
          action.mode == ActionMode.breakFor ||
          action.pauseOthers);

  Future<Result<StartActionOutcome>> call(
    int actionNameId, {
    ActionStartSource source = ActionStartSource.user,
    bool confirmed = false,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();

    final actionResult = await _actions.getById(actionNameId);
    final action = actionResult.valueOrNull;
    if (action == null) {
      return Result.failure(actionResult.errorOrNull ?? const UnknownFailure('action not found'));
    }
    final runningResult = await _runnings.currentRunning();
    final running = runningResult.valueOrNull;
    if (running == null) {
      return Result.failure(runningResult.errorOrNull ?? const UnknownFailure('no running list'));
    }

    final isSystem = source == ActionStartSource.system;
    final existing = running.firstWhereOrNull((r) => r.action.id == action.id);
    if (existing != null && existing.status == ActionStatus.active) {
      return const Result.success(StartActionOutcome.noop());
    }

    final activePomodoro = running.firstWhereOrNull(
      (r) => r.status == ActionStatus.active && r.action.mode == ActionMode.pomodoro,
    );
    final breakIsRunning = running.any(
      (r) => r.status == ActionStatus.active && r.action.mode == ActionMode.breakFor,
    );

    final effects = <TransitionEffect>[];

    if (!isSystem && activePomodoro != null && activePomodoro.action.id != action.id) {
      if (action.mode == ActionMode.pomodoro) {
        // FR-011: second Pomodoro needs confirmation; refusal changes nothing.
        if (!confirmed) {
          return Result.success(StartActionOutcome.needsConfirmation(action));
        }
        effects
          ..add(
            const TransitionEffect.pomodoroShouldStop(reason: PomodoroStopReason.secondPomodoro),
          )
          ..add(
            TransitionEffect.pomodoroInterrupted(
              byAction: action,
              interruptedAction: activePomodoro.action,
            ),
          );
        await _runnings.pause(activePomodoro.runningId, at);
      } else if (shouldInterruptPomodoro(action, isSystemTransition: false)) {
        effects
          ..add(
            TransitionEffect.pomodoroShouldStop(
              reason: action.mode == ActionMode.breakFor
                  ? PomodoroStopReason.manualBreak
                  : PomodoroStopReason.pausedByOthers,
            ),
          )
          ..add(
            TransitionEffect.pomodoroInterrupted(
              byAction: action,
              interruptedAction: activePomodoro.action,
            ),
          );
      }
    }

    if (action.pauseOthers) {
      // FR-010a: pause other active activities with pausedBySystem for
      // auto-resume. FR-010b: during a break neither the break activity nor
      // the cycle is touched.
      for (final r in running) {
        if (r.status != ActionStatus.active || r.action.id == action.id) continue;
        if (breakIsRunning && r.action.mode == ActionMode.breakFor) continue;
        await _runnings.pause(r.runningId, at, bySystem: true);
      }
    }

    if (action.mode == ActionMode.breakFor) {
      // Break puts pomodoro activities on hold until work resumes.
      for (final r in running) {
        if (r.status == ActionStatus.active &&
            r.action.mode == ActionMode.pomodoro &&
            r.action.id != action.id) {
          await _runnings.pause(r.runningId, at, bySystem: true);
        }
      }
    }

    final int runningId;
    final int historyId;
    if (existing != null) {
      final resume = await _runnings.resume(existing.runningId, at);
      if (resume.isFailure) return Result.failure(resume.errorOrNull!);
      runningId = existing.runningId;
      historyId = existing.historyId;
    } else {
      final startResult = await _runnings.start(actionNameId: action.id, now: at);
      final id = startResult.valueOrNull;
      if (id == null) {
        return Result.failure(startResult.errorOrNull ?? const UnknownFailure('start failed'));
      }
      runningId = id;
      historyId = await _historyIdOf(runningId) ?? 0;
    }

    if (action.mode == ActionMode.pomodoro) {
      effects.add(
        TransitionEffect.pomodoroShouldStart(
          actionNameId: action.id,
          historyId: historyId,
          pomodoroType: action.pomodoroType ?? PomodoroType.normal,
        ),
      );
    }
    if (action.mode == ActionMode.breakFor) {
      effects.add(TransitionEffect.breakStarted(breakActionId: action.id, historyId: historyId));
    }

    return Result.success(StartActionOutcome.started(runningId: runningId, effects: effects));
  }

  Future<int?> _historyIdOf(int runningId) async {
    final result = await _runnings.currentRunning();
    return result.valueOrNull?.firstWhereOrNull((r) => r.runningId == runningId)?.historyId;
  }
}
