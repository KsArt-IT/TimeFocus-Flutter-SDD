import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';

abstract interface class ActionRunningRepository {
  /// Sorted: active by startedAt desc, then paused by pausedAt desc (FR-005).
  Stream<List<RunningWithNameEntity>> watchRunning();

  /// Finds/creates the ActionHistory for the start date, creates a running row.
  Future<Result<int>> start({required int actionNameId, required DateTime now});

  /// Closes the current interval. [bySystem] marks pauseOthers-driven pauses
  /// for later auto-resume (FR-010a).
  Future<Result<void>> pause(int runningId, DateTime now, {bool bySystem = false});

  Future<Result<void>> resume(int runningId, DateTime now);

  /// Closes the interval and removes the running row.
  Future<Result<void>> stop(int runningId, DateTime now);

  Future<Result<int>> todayTotalSec(int actionNameId, DateTime day);

  /// Current running rows (one-shot, for use cases).
  Future<Result<List<RunningWithNameEntity>>> currentRunning();
}
