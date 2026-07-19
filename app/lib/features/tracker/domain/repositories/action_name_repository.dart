import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';

abstract interface class ActionNameRepository {
  /// Grid of a group (root when null): archived=false, ordered by sortOrder.
  Stream<List<ActionNameEntity>> watchGrid({int? groupId});

  /// Every activity — any group, archived or not (settings' activity list).
  Stream<List<ActionNameEntity>> watchAll();

  Future<Result<ActionNameEntity>> getById(int id);

  Future<Result<ActionNameEntity>> getBySystemName(String name);

  Future<Result<int>> create(ActionNameEntity e);

  Future<Result<void>> update(ActionNameEntity e);

  /// FR-043/FR-008: archiving hides an activity from the grid without
  /// deleting it — the only way to "remove" a system activity.
  Future<Result<void>> setArchived(int id, {required bool archived});

  /// Rewrites sortOrder for [orderedIds] to their list index (FR-009's drag
  /// reorder) — [orderedIds] must all share one scope (root, or one
  /// group's members), matching how [watchGrid] orders within a groupId.
  Future<Result<void>> reorder(List<int> orderedIds);

  /// isSystem → ValidationFailure; clears breakActionId references (FR-043).
  Future<Result<void>> delete(int id);
}
