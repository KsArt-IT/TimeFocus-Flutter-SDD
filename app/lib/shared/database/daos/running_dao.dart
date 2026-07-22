import 'package:drift/drift.dart';

import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/tables/action_tables.dart';
import 'package:timefocus/shared/enums/action_status.dart';

part 'running_dao.g.dart';

/// Raw join row: a running activity together with its dictionary entry.
typedef RunningWithName = ({ActionRunningModel running, ActionNameModel name});

@DriftAccessor(tables: [ActionRunnings, ActionHistories, ActionHistoryIntervals, ActionNames])
class RunningDao extends DatabaseAccessor<AppDatabase> with _$RunningDaoMixin {
  RunningDao(super.attachedDatabase);

  /// All running rows joined with names; sorting is applied by the repository.
  Stream<List<RunningWithName>> watchRunning() {
    final query = select(actionRunnings).join([
      innerJoin(actionNames, actionNames.id.equalsExp(actionRunnings.actionNameId)),
    ]);
    return query.watch().map(
      (rows) => rows
          .map(
            (r) => (running: r.readTable(actionRunnings), name: r.readTable(actionNames)),
          )
          .toList(),
    );
  }

  Future<ActionRunningModel?> getById(int id) =>
      (select(actionRunnings)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ActionRunningModel?> getByActionNameId(int actionNameId) => (select(
    actionRunnings,
  )..where((t) => t.actionNameId.equals(actionNameId))).getSingleOrNull();

  Future<List<ActionRunningModel>> allRunning() => select(actionRunnings).get();

  Future<List<ActionRunningModel>> pausedBySystem() =>
      (select(actionRunnings)..where((t) => t.pausedBySystem.equals(true))).get();

  /// Finds or creates the ActionHistorieModel for the start date and inserts an
  /// active running row. Returns the running id.
  Future<int> start({required int actionNameId, required DateTime now}) => transaction(() async {
    final day = DateTime.utc(now.year, now.month, now.day);
    final historyId = await _findOrCreateHistory(actionNameId, day);
    return into(actionRunnings).insert(
      ActionRunningsCompanion.insert(
        actionNameId: actionNameId,
        actionHistoryId: historyId,
        status: Value(ActionStatus.active.index),
        startedAt: now,
      ),
    );
  });

  /// Same as [start], but inserts the running row already paused — no open
  /// interval, nothing to close later on stop.
  Future<int> startPaused({required int actionNameId, required DateTime now}) =>
      transaction(() async {
        final day = DateTime.utc(now.year, now.month, now.day);
        final historyId = await _findOrCreateHistory(actionNameId, day);
        return into(actionRunnings).insert(
          ActionRunningsCompanion.insert(
            actionNameId: actionNameId,
            actionHistoryId: historyId,
            status: Value(ActionStatus.pause.index),
            startedAt: now,
            pausedAt: Value(now),
          ),
        );
      });

  Future<int> _findOrCreateHistory(int actionNameId, DateTime day) async {
    final existing = await (select(
      actionHistories,
    )..where((t) => t.actionNameId.equals(actionNameId) & t.date.equals(day))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(
      actionHistories,
    ).insert(ActionHistoriesCompanion.insert(actionNameId: actionNameId, date: day));
  }

  /// Closes the open interval and marks the row paused.
  Future<void> pause(int runningId, DateTime now, {bool bySystem = false}) => transaction(() async {
    final row = await getById(runningId);
    if (row == null || row.status != ActionStatus.active.index) return;
    await _closeInterval(row, now);
    final elapsed = now.difference(row.startedAt).inSeconds;
    await (update(actionRunnings)..where((t) => t.id.equals(runningId))).write(
      ActionRunningsCompanion(
        status: Value(ActionStatus.pause.index),
        pausedAt: Value(now),
        accumulatedSec: Value(row.accumulatedSec + (elapsed < 0 ? 0 : elapsed)),
        pausedBySystem: Value(bySystem),
      ),
    );
  });

  Future<void> resume(int runningId, DateTime now) async {
    await (update(actionRunnings)..where((t) => t.id.equals(runningId))).write(
      ActionRunningsCompanion(
        status: Value(ActionStatus.active.index),
        startedAt: Value(now),
        pausedAt: const Value(null),
        pausedBySystem: const Value(false),
      ),
    );
  }

  /// Closes the open interval (if active) and removes the running row.
  Future<void> stop(int runningId, DateTime now) => transaction(() async {
    final row = await getById(runningId);
    if (row == null) return;
    if (row.status == ActionStatus.active.index) {
      await _closeInterval(row, now);
    }
    await (delete(actionRunnings)..where((t) => t.id.equals(runningId))).go();
  });

  Future<void> _closeInterval(ActionRunningModel row, DateTime now) async {
    final finish = now.isBefore(row.startedAt) ? row.startedAt : now;
    await into(actionHistoryIntervals).insert(
      ActionHistoryIntervalsCompanion.insert(
        actionHistoryId: row.actionHistoryId,
        startedAt: row.startedAt,
        finishedAt: finish,
      ),
    );
  }

  /// Total recorded seconds of an activity for the day of [day] (closed intervals).
  Future<int> todayTotalSec(int actionNameId, DateTime day) async {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    final diff =
        actionHistoryIntervals.finishedAt.unixepoch - actionHistoryIntervals.startedAt.unixepoch;
    final total = diff.sum();
    final query =
        selectOnly(actionHistoryIntervals).join([
            innerJoin(
              actionHistories,
              actionHistories.id.equalsExp(actionHistoryIntervals.actionHistoryId),
            ),
          ])
          ..where(
            actionHistories.actionNameId.equals(actionNameId) & actionHistories.date.equals(dayUtc),
          )
          ..addColumns([total]);
    final row = await query.getSingle();
    return row.read(total) ?? 0;
  }
}
