import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/domain/entities/transition_effect.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_running_repository.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/action_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

/// Stop closes the interval, removes the running row, resets the Pomodoro
/// cycle (FR-014) and auto-resumes activities paused by pauseOthers (FR-010a).
@injectable
class StopActionUseCase {
  StopActionUseCase(this._runnings);

  final ActionRunningRepository _runnings;

  Future<Result<List<TransitionEffect>>> call(int runningId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final runningResult = await _runnings.currentRunning();
    final running = runningResult.valueOrNull;
    if (running == null) {
      return Result.failure(runningResult.errorOrNull ?? const UnknownFailure('no running list'));
    }
    final target = running.firstWhereOrNull((r) => r.runningId == runningId);
    if (target == null) {
      return const Result.failure(ActionFailure('running not found'));
    }

    final stopResult = await _runnings.stop(runningId, at);
    if (stopResult.isFailure) return Result.failure(stopResult.errorOrNull!);

    final effects = <TransitionEffect>[
      if (target.action.mode == ActionMode.pomodoro || target.action.mode == ActionMode.breakFor)
        const TransitionEffect.pomodoroShouldStop(reason: PomodoroStopReason.stoppedByUser),
    ];

    // FR-010a: auto-resume activities that were paused by this pauseOthers
    // activity; a resumed pomodoro activity restarts its work interval with
    // the same cycle.
    if (target.action.pauseOthers) {
      for (final r in running) {
        if (r.runningId == runningId) continue;
        if (r.status == ActionStatus.pause && r.pausedBySystem) {
          await _runnings.resume(r.runningId, at);
          if (r.action.mode == ActionMode.pomodoro) {
            effects.add(
              TransitionEffect.pomodoroShouldStart(
                actionNameId: r.action.id,
                historyId: r.historyId,
                pomodoroType: r.action.pomodoroType ?? PomodoroType.normal,
              ),
            );
          }
        }
      }
    }
    return Result.success(effects);
  }
}
