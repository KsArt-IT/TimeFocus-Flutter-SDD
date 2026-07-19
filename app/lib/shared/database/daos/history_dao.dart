import 'package:drift/drift.dart';

import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/tables/action_tables.dart';
import 'package:timefocus/shared/database/tables/pomodoro_tables.dart';
import 'package:timefocus/shared/database/tables/water_tables.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';

part 'history_dao.g.dart';

/// Interval row joined with its history record and activity.
typedef IntervalWithAction = ({
  ActionHistoryIntervalModel interval,
  ActionHistorieModel history,
  ActionNameModel name,
});

/// Aggregated totals per activity.
typedef ActionTotal = ({ActionNameModel name, int totalSec, int sessions});

@DriftAccessor(
  tables: [
    ActionHistories,
    ActionHistoryIntervals,
    ActionNames,
    PomodoroSessions,
    WaterLogs,
    DailyWaterGoals,
  ],
)
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.attachedDatabase);

  Expression<bool> _inRange(DateTime from, DateTime to) =>
      actionHistoryIntervals.startedAt.isBiggerOrEqualValue(from) &
      actionHistoryIntervals.startedAt.isSmallerThanValue(to);

  /// Total tracked seconds in range excluding the system "sleep" activity (FR-039).
  Future<int> totalSecExcludingSleep(DateTime from, DateTime to) async {
    final diff =
        actionHistoryIntervals.finishedAt.unixepoch - actionHistoryIntervals.startedAt.unixepoch;
    final total = diff.sum();
    final isSleep =
        actionNames.isSystem.equals(true) & actionNames.name.equals(SystemActionKeys.sleep);
    final query =
        selectOnly(actionHistoryIntervals).join([
            innerJoin(
              actionHistories,
              actionHistories.id.equalsExp(actionHistoryIntervals.actionHistoryId),
            ),
            innerJoin(actionNames, actionNames.id.equalsExp(actionHistories.actionNameId)),
          ])
          ..where(_inRange(from, to) & isSleep.not())
          ..addColumns([total]);
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  /// Total tracked seconds of a single system activity in range (e.g. just
  /// "Work", for the history header).
  Future<int> totalSecForSystemAction(String systemActionName, DateTime from, DateTime to) async {
    final diff =
        actionHistoryIntervals.finishedAt.unixepoch - actionHistoryIntervals.startedAt.unixepoch;
    final total = diff.sum();
    final isAction =
        actionNames.isSystem.equals(true) & actionNames.name.equals(systemActionName);
    final query =
        selectOnly(actionHistoryIntervals).join([
            innerJoin(
              actionHistories,
              actionHistories.id.equalsExp(actionHistoryIntervals.actionHistoryId),
            ),
            innerJoin(actionNames, actionNames.id.equalsExp(actionHistories.actionNameId)),
          ])
          ..where(_inRange(from, to) & isAction)
          ..addColumns([total]);
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }

  /// Completed/interrupted Pomodoro counts in range.
  Future<(int completed, int interrupted)> pomodoroCounts(DateTime from, DateTime to) async {
    final count = pomodoroSessions.id.count();
    final query = selectOnly(pomodoroSessions)
      ..where(
        pomodoroSessions.startTime.isBiggerOrEqualValue(from) &
            pomodoroSessions.startTime.isSmallerThanValue(to) &
            pomodoroSessions.status.isIn([
              PomodoroStatus.completed.index,
              PomodoroStatus.interrupted.index,
            ]),
      )
      ..addColumns([pomodoroSessions.status, count])
      ..groupBy([pomodoroSessions.status]);
    final rows = await query.get();
    var completed = 0;
    var interrupted = 0;
    for (final r in rows) {
      final status = r.read(pomodoroSessions.status);
      final c = r.read(count) ?? 0;
      if (status == PomodoroStatus.completed.index) completed = c;
      if (status == PomodoroStatus.interrupted.index) interrupted = c;
    }
    return (completed, interrupted);
  }

  /// Water drank and summed fixed goals in range.
  Future<(int drank, int goal)> waterTotals(DateTime from, DateTime to) async {
    final drankSum = waterLogs.volume.sum();
    final drankQuery = selectOnly(waterLogs)
      ..where(
        waterLogs.createdAt.isBiggerOrEqualValue(from) & waterLogs.createdAt.isSmallerThanValue(to),
      )
      ..addColumns([drankSum]);
    final drank = (await drankQuery.getSingle()).read(drankSum) ?? 0;

    final goalSum = dailyWaterGoals.goalVolume.sum();
    final goalQuery = selectOnly(dailyWaterGoals)
      ..where(
        dailyWaterGoals.date.isBiggerOrEqualValue(from) &
            dailyWaterGoals.date.isSmallerThanValue(to),
      )
      ..addColumns([goalSum]);
    final goal = (await goalQuery.getSingle()).read(goalSum) ?? 0;
    return (drank, goal);
  }

  Stream<List<IntervalWithAction>> watchIntervals(DateTime from, DateTime to) {
    final query =
        select(actionHistoryIntervals).join([
            innerJoin(
              actionHistories,
              actionHistories.id.equalsExp(actionHistoryIntervals.actionHistoryId),
            ),
            innerJoin(actionNames, actionNames.id.equalsExp(actionHistories.actionNameId)),
          ])
          ..where(_inRange(from, to))
          ..orderBy([OrderingTerm.desc(actionHistoryIntervals.startedAt)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => (
              interval: r.readTable(actionHistoryIntervals),
              history: r.readTable(actionHistories),
              name: r.readTable(actionNames),
            ),
          )
          .toList(),
    );
  }

  Stream<List<ActionTotal>> watchTotals(DateTime from, DateTime to) {
    final diff =
        actionHistoryIntervals.finishedAt.unixepoch - actionHistoryIntervals.startedAt.unixepoch;
    final total = diff.sum();
    final sessions = actionHistories.id.count(distinct: true);
    final query =
        selectOnly(actionHistoryIntervals).join([
            innerJoin(
              actionHistories,
              actionHistories.id.equalsExp(actionHistoryIntervals.actionHistoryId),
            ),
            innerJoin(actionNames, actionNames.id.equalsExp(actionHistories.actionNameId)),
          ])
          ..where(_inRange(from, to))
          ..addColumns([actionNames.id, total, sessions])
          ..groupBy([actionNames.id])
          ..orderBy([OrderingTerm.desc(total)]);
    return query.watch().asyncMap((rows) async {
      final result = <ActionTotal>[];
      for (final r in rows) {
        final nameId = r.read(actionNames.id);
        if (nameId == null) continue;
        final name = await (select(actionNames)..where((t) => t.id.equals(nameId))).getSingle();
        result.add((name: name, totalSec: r.read(total) ?? 0, sessions: r.read(sessions) ?? 0));
      }
      return result;
    });
  }

  Future<ActionHistorieModel?> getSession(int historyId) =>
      (select(actionHistories)..where((t) => t.id.equals(historyId))).getSingleOrNull();

  Future<List<ActionHistoryIntervalModel>> intervalsOfSession(int historyId) =>
      (select(actionHistoryIntervals)
            ..where((t) => t.actionHistoryId.equals(historyId))
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
          .get();

  Future<void> updateSession(int historyId, {int? newActionNameId, String? comment}) =>
      (update(actionHistories)..where((t) => t.id.equals(historyId))).write(
        ActionHistoriesCompanion(
          actionNameId: newActionNameId == null ? const Value.absent() : Value(newActionNameId),
          comment: comment == null ? const Value.absent() : Value(comment),
        ),
      );

  Future<ActionHistoryIntervalModel?> getInterval(int intervalId) =>
      (select(actionHistoryIntervals)..where((t) => t.id.equals(intervalId))).getSingleOrNull();

  Future<int> insertInterval(int historyId, DateTime startedAt, DateTime finishedAt) =>
      into(actionHistoryIntervals).insert(
        ActionHistoryIntervalsCompanion.insert(
          actionHistoryId: historyId,
          startedAt: startedAt,
          finishedAt: finishedAt,
        ),
      );

  Future<void> writeInterval(
    int intervalId, {
    required DateTime startedAt,
    required DateTime finishedAt,
  }) => (update(actionHistoryIntervals)..where((t) => t.id.equals(intervalId))).write(
    ActionHistoryIntervalsCompanion(startedAt: Value(startedAt), finishedAt: Value(finishedAt)),
  );

  /// Whether [startedAt, finishedAt) overlaps another interval of the same session.
  Future<bool> hasOverlap(
    int historyId,
    int excludeIntervalId,
    DateTime startedAt,
    DateTime finishedAt,
  ) async {
    final query = select(actionHistoryIntervals)
      ..where(
        (t) =>
            t.actionHistoryId.equals(historyId) &
            t.id.equals(excludeIntervalId).not() &
            t.startedAt.isSmallerThanValue(finishedAt) &
            t.finishedAt.isBiggerThanValue(startedAt),
      )
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  Future<void> deleteInterval(int intervalId) =>
      (delete(actionHistoryIntervals)..where((t) => t.id.equals(intervalId))).go();

  /// Cascade removes intervals via FK.
  Future<void> deleteSession(int historyId) =>
      (delete(actionHistories)..where((t) => t.id.equals(historyId))).go();

  /// Total seconds per day in range (for report charts), keyed by day start.
  Future<Map<DateTime, int>> totalsByDay(DateTime from, DateTime to) async {
    final rows =
        await (select(actionHistoryIntervals)..where(
              (t) => t.startedAt.isBiggerOrEqualValue(from) & t.startedAt.isSmallerThanValue(to),
            ))
            .get();
    final result = <DateTime, int>{};
    for (final r in rows) {
      final day = DateTime.utc(r.startedAt.year, r.startedAt.month, r.startedAt.day);
      final sec = r.finishedAt.difference(r.startedAt).inSeconds;
      result[day] = (result[day] ?? 0) + (sec < 0 ? 0 : sec);
    }
    return result;
  }
}
