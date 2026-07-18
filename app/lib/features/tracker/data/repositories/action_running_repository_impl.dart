import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/data/mappers/action_mappers.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_running_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/action_status.dart';

@LazySingleton(as: ActionRunningRepository)
class ActionRunningRepositoryImpl with SafeCallMixin implements ActionRunningRepository {
  ActionRunningRepositoryImpl(this._db);

  final AppDatabase _db;

  List<RunningWithNameEntity> _sorted(List<RunningWithNameEntity> list) {
    final active = list.where((r) => r.status == ActionStatus.active).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final paused = list.where((r) => r.status == ActionStatus.pause).toList()
      ..sort((a, b) {
        final ap = a.pausedAt ?? a.startedAt;
        final bp = b.pausedAt ?? b.startedAt;
        return bp.compareTo(ap);
      });
    return [...active, ...paused];
  }

  @override
  Stream<List<RunningWithNameEntity>> watchRunning() => _db.runningDao.watchRunning().map(
    (rows) => _sorted(rows.map((r) => r.toEntity()).toList()),
  );

  @override
  Future<Result<int>> start({required int actionNameId, required DateTime now}) => safeCall(
    () => _db.runningDao.start(actionNameId: actionNameId, now: now),
  );

  @override
  Future<Result<void>> pause(int runningId, DateTime now, {bool bySystem = false}) => voidSafeCall(
    () => _db.runningDao.pause(runningId, now, bySystem: bySystem),
  );

  @override
  Future<Result<void>> resume(int runningId, DateTime now) => voidSafeCall(
    () => _db.runningDao.resume(runningId, now),
  );

  @override
  Future<Result<void>> stop(int runningId, DateTime now) => voidSafeCall(
    () => _db.runningDao.stop(runningId, now),
  );

  @override
  Future<Result<int>> todayTotalSec(int actionNameId, DateTime day) => safeCall(
    () => _db.runningDao.todayTotalSec(actionNameId, day),
  );

  @override
  Future<Result<List<RunningWithNameEntity>>> currentRunning() => safeCall(() async {
    final rows = await _db.runningDao.watchRunning().first;
    return _sorted(rows.map((r) => r.toEntity()).toList());
  });
}
