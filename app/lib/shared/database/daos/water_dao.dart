import 'package:drift/drift.dart';

import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/tables/water_tables.dart';

part 'water_dao.g.dart';

@DriftAccessor(
  tables: [WaterSettings, WaterReminderTimes, WaterQuickButtons, WaterLogs, DailyWaterGoals],
)
class WaterDao extends DatabaseAccessor<AppDatabase> with _$WaterDaoMixin {
  WaterDao(super.attachedDatabase);

  static const int _singletonId = 1;

  Stream<int> watchDrankBetween(DateTime from, DateTime to) {
    final total = waterLogs.volume.sum();
    final query = selectOnly(waterLogs)
      ..where(
        waterLogs.createdAt.isBiggerOrEqualValue(from) & waterLogs.createdAt.isSmallerThanValue(to),
      )
      ..addColumns([total]);
    return query.watchSingle().map((row) => row.read(total) ?? 0);
  }

  /// Individual log rows in range, oldest first (for the schedule timeline).
  Stream<List<WaterLogModel>> watchLogsBetween(DateTime from, DateTime to) =>
      (select(waterLogs)
            ..where(
              (t) => t.createdAt.isBiggerOrEqualValue(from) & t.createdAt.isSmallerThanValue(to),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<void> insertLog(int volume, DateTime now) => transaction(() async {
    await into(waterLogs).insert(WaterLogsCompanion.insert(volume: volume, createdAt: now));
    await (update(waterSettings)..where((t) => t.id.equals(_singletonId))).write(
      WaterSettingsCompanion(lastDrankAt: Value(now)),
    );
  });

  Future<WaterLogModel?> getLogById(int id) =>
      (select(waterLogs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateLog(int id, {required int volume, required DateTime createdAt}) =>
      (update(waterLogs)..where((t) => t.id.equals(id))).write(
        WaterLogsCompanion(
          volume: Value(volume),
          createdAt: Value(createdAt),
        ),
      );

  Future<void> deleteLog(int id) => (delete(waterLogs)..where((t) => t.id.equals(id))).go();

  Future<WaterSettingModel> getSettings() =>
      (select(waterSettings)..where((t) => t.id.equals(_singletonId))).getSingle();

  Stream<WaterSettingModel> watchSettings() =>
      (select(waterSettings)..where((t) => t.id.equals(_singletonId))).watchSingle();

  Future<void> saveSettings(WaterSettingsCompanion companion) =>
      (update(waterSettings)..where((t) => t.id.equals(_singletonId))).write(companion);

  Stream<List<WaterQuickButtonModel>> watchQuickButtons() =>
      (select(waterQuickButtons)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> saveQuickButton(WaterQuickButtonsCompanion companion) async {
    if (companion.id.present) {
      await (update(
        waterQuickButtons,
      )..where((t) => t.id.equals(companion.id.value))).write(companion);
    } else {
      await into(waterQuickButtons).insert(companion);
    }
  }

  Future<List<int>> reminderTimes() async {
    final rows = await (select(
      waterReminderTimes,
    )..orderBy([(t) => OrderingTerm.asc(t.timeMinutes)])).get();
    return rows.map((r) => r.timeMinutes).toList();
  }

  Future<void> replaceReminderTimes(List<int> times) => transaction(() async {
    await delete(waterReminderTimes).go();
    for (final t in times) {
      await into(waterReminderTimes).insert(WaterReminderTimesCompanion.insert(timeMinutes: t));
    }
  });

  Future<DailyWaterGoalModel?> goalForDay(DateTime day) =>
      (select(dailyWaterGoals)..where((t) => t.date.equals(day))).getSingleOrNull();

  /// Fixes the goal for [day] if not fixed yet.
  Future<void> ensureDailyGoal(DateTime day, int goalVolume) async {
    await into(dailyWaterGoals).insert(
      DailyWaterGoalsCompanion.insert(date: day, goalVolume: goalVolume),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<(int drank, int goal)> totalByPeriod(DateTime from, DateTime to) =>
      db.historyDao.waterTotals(from, to);

  /// Water volume per day in range, keyed by day start (for reports).
  Future<Map<DateTime, int>> drankByDay(DateTime from, DateTime to) async {
    final rows =
        await (select(waterLogs)..where(
              (t) => t.createdAt.isBiggerOrEqualValue(from) & t.createdAt.isSmallerThanValue(to),
            ))
            .get();
    final result = <DateTime, int>{};
    for (final r in rows) {
      final day = DateTime.utc(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      result[day] = (result[day] ?? 0) + r.volume;
    }
    return result;
  }
}
