import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/pomodoro/data/mappers/pomodoro_mappers.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_session_entity.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

@LazySingleton(as: PomodoroRepository)
class PomodoroRepositoryImpl with SafeCallMixin implements PomodoroRepository {
  PomodoroRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<PomodoroSessionEntity>> startSession({
    required int actionNameId,
    required int historyId,
    required PomodoroType type,
    required int cycleNumber,
    required bool isBreak,
  }) => safeCall(() async {
    final settings = await _db.pomodoroDao.currentSettings();
    final plannedTime = isBreak
        ? settings.toEntity().breakTimeFor(isLong: type == PomodoroType.long)
        : settings.toEntity().workTimeFor(type);
    final now = DateTime.now();
    final id = await _db.pomodoroDao.insertSession(
      PomodoroSessionEntity(
        id: 0,
        actionNameId: actionNameId,
        actionHistoryId: historyId,
        settingsId: settings.id,
        type: type,
        plannedTime: plannedTime,
        startTime: now,
        cycleNumber: cycleNumber,
      ).toCompanion(),
    );
    final session = await _db.pomodoroDao.getSession(id);
    return session!.toEntity();
  });

  @override
  Future<Result<void>> finish(int sessionId, PomodoroStatus status, DateTime now) => voidSafeCall(
    () => _db.pomodoroDao.finishSession(sessionId, status, now),
  );

  @override
  Future<Result<PomodoroSessionEntity?>> activeSession() => safeCall(
    () async => (await _db.pomodoroDao.activeSession())?.toEntity(),
  );

  @override
  Future<Result<PomodoroSessionEntity?>> lastSessionForAction(int actionNameId) => safeCall(
    () async => (await _db.pomodoroDao.lastSessionForAction(actionNameId))?.toEntity(),
  );

  @override
  Future<Result<(int completed, int interrupted)>> countByPeriod(
    DateTime from,
    DateTime to,
  ) => safeCall(
    () => _db.pomodoroDao.countByPeriod(from, to),
  );
}
