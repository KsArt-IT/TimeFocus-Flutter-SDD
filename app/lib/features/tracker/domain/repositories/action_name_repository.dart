import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';

abstract interface class ActionNameRepository {
  /// Grid of a group (root when null): archived=false, ordered by sortOrder.
  Stream<List<ActionNameEntity>> watchGrid({int? groupId});

  Future<Result<ActionNameEntity>> getById(int id);

  Future<Result<int>> create(ActionNameEntity e);

  Future<Result<void>> update(ActionNameEntity e);

  Future<Result<void>> archive(int id);

  /// isSystem → ValidationFailure; clears breakActionId references (FR-043).
  Future<Result<void>> delete(int id);
}
