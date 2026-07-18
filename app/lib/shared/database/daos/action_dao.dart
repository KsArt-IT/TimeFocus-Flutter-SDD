import 'package:drift/drift.dart';

import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/tables/action_tables.dart';

part 'action_dao.g.dart';

@DriftAccessor(tables: [ActionNames])
class ActionDao extends DatabaseAccessor<AppDatabase> with _$ActionDaoMixin {
  ActionDao(super.attachedDatabase);

  /// Grid of a group (or root when [groupId] is null): not archived, by sortOrder.
  Stream<List<ActionNameModel>> watchGrid({int? groupId}) {
    final query = select(actionNames)
      ..where((t) => t.archived.equals(false))
      ..where((t) => groupId == null ? t.groupId.isNull() : t.groupId.equals(groupId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]);
    return query.watch();
  }

  Stream<List<ActionNameModel>> watchAll() {
    final query = select(actionNames)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]);
    return query.watch();
  }

  Future<ActionNameModel?> getById(int id) =>
      (select(actionNames)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ActionNameModel?> getBySystemName(String name) => (select(
    actionNames,
  )..where((t) => t.isSystem.equals(true) & t.name.equals(name))).getSingleOrNull();

  Future<int> insertAction(ActionNamesCompanion companion) => into(actionNames).insert(companion);

  Future<bool> updateAction(ActionNamesCompanion companion) =>
      update(actionNames).replace(companion);

  Future<void> setArchived(int id, {required bool archived}) => (update(
    actionNames,
  )..where((t) => t.id.equals(id))).write(ActionNamesCompanion(archived: Value(archived)));

  /// Deletes a user activity; clears breakActionId references pointing at it.
  /// ScheduleEvents.actionId is cleared by FK setNull.
  Future<void> deleteAction(int id) => transaction(() async {
    await (update(actionNames)..where(
          (t) => t.breakActionId.equals(id),
        ))
        .write(const ActionNamesCompanion(breakActionId: Value(null)));
    await (delete(actionNames)..where((t) => t.id.equals(id))).go();
  });
}
