import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_session_entity.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

abstract interface class PomodoroRepository {
  /// Starts a session snapshotting the current settings row. [isBreak]
  /// selects break vs. work duration bucket for [type] (short/long).
  Future<Result<PomodoroSessionEntity>> startSession({
    required int actionNameId,
    required int historyId,
    required PomodoroType type,
    required int cycleNumber,
    required bool isBreak,
  });

  Future<Result<void>> finish(int sessionId, PomodoroStatus status, DateTime now);

  Future<Result<PomodoroSessionEntity?>> activeSession();

  Future<Result<PomodoroSessionEntity?>> lastSessionForAction(int actionNameId);

  Future<Result<(int completed, int interrupted)>> countByPeriod(DateTime from, DateTime to);
}
