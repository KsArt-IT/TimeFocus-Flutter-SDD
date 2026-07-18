import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/domain/entities/transition_effect.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_running_repository.dart';
import 'package:timefocus/shared/enums/action_mode.dart';

/// Pausing a pomodoro activity interrupts the work interval (FR-018a).
@injectable
class PauseActionUseCase {
  PauseActionUseCase(this._runnings);

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

    final pauseResult = await _runnings.pause(runningId, at);
    if (pauseResult.isFailure) return Result.failure(pauseResult.errorOrNull!);

    final effects = <TransitionEffect>[
      if (target.action.mode == ActionMode.pomodoro)
        const TransitionEffect.pomodoroShouldStop(reason: PomodoroStopReason.pausedByUser),
    ];
    return Result.success(effects);
  }
}
