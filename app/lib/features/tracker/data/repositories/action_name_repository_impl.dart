import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/data/mappers/action_mappers.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';

@LazySingleton(as: ActionNameRepository)
class ActionNameRepositoryImpl with SafeCallMixin implements ActionNameRepository {
  ActionNameRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ActionNameEntity>> watchGrid({int? groupId}) => _db.actionDao
      .watchGrid(groupId: groupId)
      .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<Result<ActionNameEntity>> getById(int id) => safeCall(() async {
    final row = await _db.actionDao.getById(id);
    if (row == null) {
      throw const DatabaseFailure('action not found', code: DatabaseFailure.entityNotFound);
    }
    return row.toEntity();
  });

  @override
  Future<Result<int>> create(ActionNameEntity e) => safeCall(
    () => _db.actionDao.insertAction(e.toCompanion(includeId: false)),
  );

  @override
  Future<Result<void>> update(ActionNameEntity e) => voidSafeCall(
    () => _db.actionDao.updateAction(e.toCompanion()),
  );

  @override
  Future<Result<void>> archive(int id) => voidSafeCall(
    () => _db.actionDao.setArchived(id, archived: true),
  );

  @override
  Future<Result<void>> delete(int id) => voidSafeCall(() async {
    final row = await _db.actionDao.getById(id);
    if (row == null) {
      throw const DatabaseFailure('action not found', code: DatabaseFailure.entityNotFound);
    }
    if (row.isSystem) {
      throw const ValidationFailure('system actions cannot be deleted');
    }
    await _db.actionDao.deleteAction(id);
  });
}
