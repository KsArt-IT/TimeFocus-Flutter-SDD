import 'package:drift/drift.dart';

import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/tables/pomodoro_tables.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';

part 'pomodoro_dao.g.dart';

@DriftAccessor(tables: [PomodoroSessions, PomodoroSettings])
class PomodoroDao extends DatabaseAccessor<AppDatabase> with _$PomodoroDaoMixin {
  PomodoroDao(super.attachedDatabase);

  Future<int> insertSession(PomodoroSessionsCompanion companion) =>
      into(pomodoroSessions).insert(companion);

  Future<PomodoroSessionModel?> getSession(int id) =>
      (select(pomodoroSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> finishSession(int id, PomodoroStatus status, DateTime now) async {
    final session = await getSession(id);
    if (session == null) return;
    final actual = now.difference(session.startTime).inSeconds;
    await (update(pomodoroSessions)..where((t) => t.id.equals(id))).write(
      PomodoroSessionsCompanion(
        status: Value(status.index),
        endTime: Value(now),
        actualTime: Value(actual < 0 ? 0 : actual),
      ),
    );
  }

  Future<PomodoroSessionModel?> activeSession() =>
      (select(pomodoroSessions)
            ..where((t) => t.status.equals(PomodoroStatus.active.index))
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
            ..limit(1))
          .getSingleOrNull();

  /// Latest session of an activity (any status) — used for cycle continuation.
  Future<PomodoroSessionModel?> lastSessionForAction(int actionNameId) =>
      (select(pomodoroSessions)
            ..where((t) => t.actionNameId.equals(actionNameId))
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
            ..limit(1))
          .getSingleOrNull();

  Future<(int completed, int interrupted)> countByPeriod(DateTime from, DateTime to) =>
      db.historyDao.pomodoroCounts(from, to);

  Future<PomodoroSettingModel> currentSettings() =>
      (select(pomodoroSettings)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingle();

  Stream<PomodoroSettingModel> watchSettings() =>
      (select(pomodoroSettings)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .watchSingle();

  Future<int> insertSettings(PomodoroSettingsCompanion companion) =>
      into(pomodoroSettings).insert(companion);
}
