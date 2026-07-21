import 'package:injectable/injectable.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/history/data/mappers/history_mappers.dart';
import 'package:timefocus/features/history/domain/entities/history_header_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_edit.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_total_entity.dart';
import 'package:timefocus/features/history/domain/repositories/history_repository.dart';
import 'package:timefocus/features/water/data/mappers/water_mappers.dart';
import 'package:timefocus/features/water/domain/entities/water_log_entity.dart';
import 'package:timefocus/shared/database/app_database.dart';

@LazySingleton(as: HistoryRepository)
class HistoryRepositoryImpl with SafeCallMixin implements HistoryRepository {
  HistoryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<HistoryHeaderEntity>> header(DateTime from, DateTime to) => safeCall(() async {
    final totalSec = await _db.historyDao.totalSecExcludingSleep(from, to);
    final workSec = await _db.historyDao.totalSecForSystemAction(
      SystemActionKeys.work.name,
      from,
      to,
    );
    final (completed, interrupted) = await _db.pomodoroDao.countByPeriod(from, to);
    final (drank, goal) = await _db.waterDao.totalByPeriod(from, to);
    return HistoryHeaderEntity(
      totalSec: totalSec,
      workSec: workSec,
      pomodoroCompleted: completed,
      pomodoroInterrupted: interrupted,
      waterDrankMl: drank,
      waterGoalMl: goal,
    );
  });

  @override
  Stream<List<HistoryIntervalEntity>> watchIntervals(DateTime from, DateTime to) => _db.historyDao
      .watchIntervals(from, to)
      .map(
        (rows) => rows.map((r) => r.toEntity()).toList(),
      );

  @override
  Stream<List<HistoryTotalEntity>> watchTotals(DateTime from, DateTime to) => _db.historyDao
      .watchTotals(from, to)
      .map(
        (rows) => rows.map((r) => r.toEntity()).toList(),
      );

  @override
  Stream<List<WaterLogEntity>> watchWaterLogs(DateTime from, DateTime to) => _db.waterDao
      .watchLogsBetween(from, to)
      .map(
        (rows) => rows.map((r) => r.toEntity()).toList(),
      );

  @override
  Future<Result<HistorySessionEntity>> session(int historyId) => safeCall(() async {
    final history = await _db.historyDao.getSession(historyId);
    if (history == null) {
      throw const DatabaseFailure('session not found', code: DatabaseFailure.entityNotFound);
    }
    final intervals = await _db.historyDao.intervalsOfSession(historyId);
    return history.toEntity(intervals);
  });

  @override
  Future<Result<void>> updateSession({
    required int historyId,
    int? newActionNameId,
    String? comment,
  }) => voidSafeCall(
    () => _db.historyDao.updateSession(
      historyId,
      newActionNameId: newActionNameId,
      comment: comment,
    ),
  );

  @override
  Future<Result<int?>> findConflictingSession({
    required int actionNameId,
    required DateTime date,
    required int excludingHistoryId,
  }) => safeCall(
    () => _db.historyDao.findHistoryId(actionNameId, date, excludingId: excludingHistoryId),
  );

  @override
  Future<Result<void>> mergeSessions({required int fromHistoryId, required int intoHistoryId}) =>
      voidSafeCall(() => _db.historyDao.mergeSessions(fromHistoryId, intoHistoryId));

  @override
  Future<Result<OverlapCheck>> saveInterval(HistoryIntervalEdit e) => safeCall(() async {
    if (e.finishedAt.isBefore(e.startedAt)) {
      throw const ValidationFailure('finishedAt before startedAt');
    }
    final overlaps = await _db.historyDao.hasOverlap(
      e.historyId,
      e.id ?? 0,
      e.startedAt,
      e.finishedAt,
    );
    if (e.id != null) {
      await _db.historyDao.writeInterval(e.id!, startedAt: e.startedAt, finishedAt: e.finishedAt);
    } else {
      await _db.historyDao.insertInterval(e.historyId, e.startedAt, e.finishedAt);
    }
    return overlaps ? OverlapCheck.warning : OverlapCheck.ok;
  });

  @override
  Future<Result<void>> deleteInterval(int intervalId) => voidSafeCall(
    () => _db.historyDao.deleteInterval(intervalId),
  );

  @override
  Future<Result<void>> deleteSession(int historyId) => voidSafeCall(
    () => _db.historyDao.deleteSession(historyId),
  );

  @override
  Future<Result<Map<DateTime, int>>> totalsByDay(DateTime from, DateTime to) => safeCall(
    () => _db.historyDao.totalsByDay(from, to),
  );

  @override
  Future<Result<Map<DateTime, int>>> waterByDay(DateTime from, DateTime to) => safeCall(
    () => _db.waterDao.drankByDay(from, to),
  );
}
