import 'package:injectable/injectable.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/water/data/mappers/hud_queue_mappers.dart';
import 'package:timefocus/features/water/domain/entities/hud_queue_item_entity.dart';
import 'package:timefocus/features/water/domain/repositories/hud_queue_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';

@LazySingleton(as: HudQueueRepository)
class HudQueueRepositoryImpl with SafeCallMixin implements HudQueueRepository {
  HudQueueRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<HudQueueItemEntity>> watchActive(DateTime day) => _db.hudQueueDao
      .watchActive(day)
      .map((rows) => rows.map((r) => r.toEntity()).whereType<HudQueueItemEntity>().toList());

  @override
  Future<Result<void>> raise(SystemAction action, DateTime day) => voidSafeCall(
    () => _db.hudQueueDao.upsert(action.name, day, DateTime.now()),
  );

  @override
  Future<Result<void>> raiseIfNew(SystemAction action, DateTime day) => voidSafeCall(
    () => _db.hudQueueDao.insertIfAbsent(action.name, day, DateTime.now()),
  );

  @override
  Future<Result<void>> dismiss(int id) => voidSafeCall(() => _db.hudQueueDao.dismiss(id));

  @override
  Future<Result<void>> purgeStale(DateTime today) => voidSafeCall(
    () => _db.hudQueueDao.deleteNotToday(today),
  );
}
