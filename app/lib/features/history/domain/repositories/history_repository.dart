import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/history/domain/entities/history_header_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_edit.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_total_entity.dart';

abstract interface class HistoryRepository {
  /// totalSec excludes the system "Sleep" activity (FR-039).
  Future<Result<HistoryHeaderEntity>> header(DateTime from, DateTime to);

  Stream<List<HistoryIntervalEntity>> watchIntervals(DateTime from, DateTime to);

  Stream<List<HistoryTotalEntity>> watchTotals(DateTime from, DateTime to);

  Future<Result<HistorySessionEntity>> session(int historyId);

  Future<Result<void>> updateSession({
    required int historyId,
    int? newActionNameId,
    String? comment,
  });

  /// The other session already recorded for [actionNameId] on [date] (if
  /// any), excluding [excludingHistoryId] — ActionHistories has a unique
  /// (actionNameId, date) key, so the caller must merge instead of updating
  /// in place when this returns non-null.
  Future<Result<int?>> findConflictingSession({
    required int actionNameId,
    required DateTime date,
    required int excludingHistoryId,
  });

  /// Moves every interval of [fromHistoryId] under [intoHistoryId] and
  /// removes the now-empty source session.
  Future<Result<void>> mergeSessions({required int fromHistoryId, required int intoHistoryId});

  /// finishedAt < startedAt -> ValidationFailure; overlapping another
  /// interval of the same activity -> OverlapCheck.warning, saved anyway.
  Future<Result<OverlapCheck>> saveInterval(HistoryIntervalEdit e);

  Future<Result<void>> deleteInterval(int intervalId);

  /// Cascades to all of the session's intervals.
  Future<Result<void>> deleteSession(int historyId);

  /// Tracked seconds per day in range, keyed by day start (Reports charts).
  Future<Result<Map<DateTime, int>>> totalsByDay(DateTime from, DateTime to);

  /// Water drunk per day in range, keyed by day start (Reports charts).
  Future<Result<Map<DateTime, int>>> waterByDay(DateTime from, DateTime to);
}
