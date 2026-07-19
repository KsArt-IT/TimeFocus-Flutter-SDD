import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/action_status.dart';

void main() {
  late AppDatabase db;
  late int workId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final work = await db.actionDao.getBySystemName(SystemActionKeys.work);
    workId = work!.id;
  });

  tearDown(() => db.close());

  test('start creates history for the start date and an active running row', () async {
    final now = DateTime(2026, 7, 18, 10);
    final runningId = await db.runningDao.start(actionNameId: workId, now: now);

    final running = await db.runningDao.getById(runningId);
    expect(running!.status, ActionStatus.active.index);
    expect(running.startedAt, now);
    expect(running.accumulatedSec, 0);

    final history = await db.historyDao.getSession(running.actionHistoryId);
    expect(history!.actionNameId, workId);
    expect(history.date.toUtc(), DateTime.utc(2026, 7, 18));
  });

  test('start on the same day reuses the history record', () async {
    final id1 = await db.runningDao.start(actionNameId: workId, now: DateTime(2026, 7, 18, 10));
    final r1 = await db.runningDao.getById(id1);
    await db.runningDao.stop(id1, DateTime(2026, 7, 18, 10, 30));

    final id2 = await db.runningDao.start(actionNameId: workId, now: DateTime(2026, 7, 18, 12));
    final r2 = await db.runningDao.getById(id2);
    expect(r1!.actionHistoryId, r2!.actionHistoryId);
  });

  test(
    'pause closes interval and accumulates; resume opens fresh interval; stop finishes',
    () async {
      final start = DateTime(2026, 7, 18, 10);
      final runningId = await db.runningDao.start(actionNameId: workId, now: start);

      // pause after 10 minutes
      await db.runningDao.pause(runningId, start.add(const Duration(minutes: 10)));
      var running = await db.runningDao.getById(runningId);
      expect(running!.status, ActionStatus.pause.index);
      expect(running.accumulatedSec, 600);

      var intervals = await db.historyDao.intervalsOfSession(running.actionHistoryId);
      expect(intervals.length, 1);
      expect(intervals.single.finishedAt.difference(intervals.single.startedAt).inSeconds, 600);

      // resume after 5 min break, work 20 more minutes, then stop
      final resumeAt = start.add(const Duration(minutes: 15));
      await db.runningDao.resume(runningId, resumeAt);
      running = await db.runningDao.getById(runningId);
      expect(running!.status, ActionStatus.active.index);
      expect(running.startedAt, resumeAt);

      final historyId = running.actionHistoryId;
      await db.runningDao.stop(runningId, resumeAt.add(const Duration(minutes: 20)));
      expect(await db.runningDao.getById(runningId), isNull);

      intervals = await db.historyDao.intervalsOfSession(historyId);
      expect(intervals.length, 2);

      final total = await db.runningDao.todayTotalSec(workId, start);
      expect(total, 600 + 1200);
    },
  );

  test('pause bySystem sets the flag and resume clears it', () async {
    final start = DateTime(2026, 7, 18, 10);
    final runningId = await db.runningDao.start(actionNameId: workId, now: start);
    await db.runningDao.pause(runningId, start.add(const Duration(minutes: 1)), bySystem: true);

    var running = await db.runningDao.getById(runningId);
    expect(running!.pausedBySystem, isTrue);
    expect((await db.runningDao.pausedBySystem()).length, 1);

    await db.runningDao.resume(runningId, start.add(const Duration(minutes: 2)));
    running = await db.runningDao.getById(runningId);
    expect(running!.pausedBySystem, isFalse);
  });

  test('stop of a paused running does not add an extra interval', () async {
    final start = DateTime(2026, 7, 18, 10);
    final runningId = await db.runningDao.start(actionNameId: workId, now: start);
    await db.runningDao.pause(runningId, start.add(const Duration(minutes: 10)));
    final running = await db.runningDao.getById(runningId);

    await db.runningDao.stop(runningId, start.add(const Duration(minutes: 30)));
    final intervals = await db.historyDao.intervalsOfSession(running!.actionHistoryId);
    expect(intervals.length, 1);
  });

  test(
    'startPaused creates a paused row with no interval; stopping it right away adds none either',
    () async {
      final now = DateTime(2026, 7, 18, 10);
      final runningId = await db.runningDao.startPaused(actionNameId: workId, now: now);

      final running = await db.runningDao.getById(runningId);
      expect(running!.status, ActionStatus.pause.index);
      expect(running.pausedAt, now);
      expect(running.accumulatedSec, 0);

      var intervals = await db.historyDao.intervalsOfSession(running.actionHistoryId);
      expect(intervals, isEmpty);

      await db.runningDao.stop(runningId, now.add(const Duration(minutes: 5)));
      intervals = await db.historyDao.intervalsOfSession(running.actionHistoryId);
      expect(intervals, isEmpty);
    },
  );
}
