import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/features/history/data/repositories/history_repository_impl.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_edit.dart';
import 'package:timefocus/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late HistoryRepositoryImpl repository;
  late int workId;
  late int sleepId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = HistoryRepositoryImpl(db);
    workId = (await db.actionDao.getBySystemName(SystemActionKeys.work))!.id;
    sleepId = (await db.actionDao.getBySystemName(SystemActionKeys.sleep))!.id;
  });

  tearDown(() => db.close());

  group('header (FR-039)', () {
    test('totalSec excludes the system Sleep activity', () async {
      final from = DateTime.utc(2026, 7, 18);
      final to = from.add(const Duration(days: 1));
      final workRunningId = await db.runningDao.start(
        actionNameId: workId,
        now: DateTime(2026, 7, 18, 9),
      );
      await db.runningDao.stop(workRunningId, DateTime(2026, 7, 18, 10));
      final sleepRunningId = await db.runningDao.start(
        actionNameId: sleepId,
        now: DateTime(2026, 7, 18, 23),
      );
      await db.runningDao.stop(sleepRunningId, DateTime(2026, 7, 19, 7));

      final result = await repository.header(from, to);
      expect(result.isSuccess, isTrue);
      // Only the 1-hour work interval counts; the (much longer) sleep
      // interval starting the same UTC day is excluded entirely.
      expect(result.valueOrNull!.totalSec, const Duration(hours: 1).inSeconds);
    });
  });

  group('session spanning midnight (data-model.md — attributed to the start day)', () {
    test('a session started before midnight keeps its single history record', () async {
      final start = DateTime(2026, 7, 18, 23, 30);
      final end = DateTime(2026, 7, 19, 0, 30);
      final runningId = await db.runningDao.start(actionNameId: workId, now: start);
      await db.runningDao.stop(runningId, end);

      final sessionResult = await repository.header(
        DateTime.utc(2026, 7, 18),
        DateTime.utc(2026, 7, 19),
      );
      expect(sessionResult.valueOrNull!.totalSec, const Duration(hours: 1).inSeconds);

      // The interval itself is NOT split at midnight (clarification).
      final intervals = await repository
          .watchIntervals(start, end.add(const Duration(hours: 1)))
          .first;
      expect(intervals, hasLength(1));
      expect(intervals.single.startedAt, start);
      expect(intervals.single.finishedAt, end);
    });
  });

  group('saveInterval OverlapCheck (FR-040)', () {
    test('end before start is rejected as a ValidationFailure', () async {
      final runningId = await db.runningDao.start(
        actionNameId: workId,
        now: DateTime(2026, 7, 18, 10),
      );
      await db.runningDao.stop(runningId, DateTime(2026, 7, 18, 11));
      final historyId = (await db.historyDao.getSession(1))!.id;

      final result = await repository.saveInterval(
        HistoryIntervalEdit(
          historyId: historyId,
          startedAt: DateTime(2026, 7, 18, 12),
          finishedAt: DateTime(2026, 7, 18, 11),
        ),
      );
      expect(result.isFailure, isTrue);
    });

    test('a non-overlapping new interval saves as ok', () async {
      final runningId = await db.runningDao.start(
        actionNameId: workId,
        now: DateTime(2026, 7, 18, 10),
      );
      await db.runningDao.stop(runningId, DateTime(2026, 7, 18, 11));
      final historyId = (await db.historyDao.getSession(1))!.id;

      final result = await repository.saveInterval(
        HistoryIntervalEdit(
          historyId: historyId,
          startedAt: DateTime(2026, 7, 18, 14),
          finishedAt: DateTime(2026, 7, 18, 15),
        ),
      );
      expect(result.valueOrNull, OverlapCheck.ok);

      final intervals = await db.historyDao.intervalsOfSession(historyId);
      expect(intervals, hasLength(2));
    });

    test('an overlapping interval is still saved, but warns', () async {
      final runningId = await db.runningDao.start(
        actionNameId: workId,
        now: DateTime(2026, 7, 18, 10),
      );
      await db.runningDao.stop(runningId, DateTime(2026, 7, 18, 12));
      final historyId = (await db.historyDao.getSession(1))!.id;

      final result = await repository.saveInterval(
        HistoryIntervalEdit(
          historyId: historyId,
          startedAt: DateTime(2026, 7, 18, 11),
          finishedAt: DateTime(2026, 7, 18, 13),
        ),
      );
      expect(result.valueOrNull, OverlapCheck.warning);

      final intervals = await db.historyDao.intervalsOfSession(historyId);
      expect(intervals, hasLength(2));
    });

    test('editing an interval in place does not flag itself as an overlap', () async {
      final runningId = await db.runningDao.start(
        actionNameId: workId,
        now: DateTime(2026, 7, 18, 10),
      );
      await db.runningDao.stop(runningId, DateTime(2026, 7, 18, 11));
      final historyId = (await db.historyDao.getSession(1))!.id;
      final intervalId = (await db.historyDao.intervalsOfSession(historyId)).single.id;

      final result = await repository.saveInterval(
        HistoryIntervalEdit(
          id: intervalId,
          historyId: historyId,
          startedAt: DateTime(2026, 7, 18, 10, 5),
          finishedAt: DateTime(2026, 7, 18, 11, 5),
        ),
      );
      expect(result.valueOrNull, OverlapCheck.ok);
    });
  });
}
