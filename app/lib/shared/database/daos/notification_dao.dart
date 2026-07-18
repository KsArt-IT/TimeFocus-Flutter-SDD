import 'package:drift/drift.dart';

import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/tables/app_tables.dart';

part 'notification_dao.g.dart';

@DriftAccessor(tables: [Notifications])
class NotificationDao extends DatabaseAccessor<AppDatabase> with _$NotificationDaoMixin {
  NotificationDao(super.attachedDatabase);

  Future<void> insertNotification(NotificationsCompanion companion) =>
      into(notifications).insert(companion, mode: InsertMode.insertOrReplace);

  Future<void> deleteNotification(int id) =>
      (delete(notifications)..where((t) => t.id.equals(id))).go();

  Future<void> deleteByType(int type) =>
      (delete(notifications)..where((t) => t.type.equals(type))).go();

  Future<List<NotificationModel>> pendingAfter(DateTime after) =>
      (select(notifications)
            ..where((t) => t.isDelivered.equals(false) & t.scheduledAt.isBiggerThanValue(after))
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
          .get();

  Future<List<NotificationModel>> undeliveredOfType(int type) => (select(
    notifications,
  )..where((t) => t.isDelivered.equals(false) & t.type.equals(type))).get();

  Future<List<NotificationModel>> allUndelivered() =>
      (select(notifications)..where((t) => t.isDelivered.equals(false))).get();

  Future<void> markDelivered(int id) =>
      (update(notifications)..where(
            (t) => t.id.equals(id),
          ))
          .write(const NotificationsCompanion(isDelivered: Value(true)));

  /// Next free notification id (plugin ids must be stable ints).
  Future<int> nextId() async {
    final maxId = notifications.id.max();
    final query = selectOnly(notifications)..addColumns([maxId]);
    final row = await query.getSingle();
    return (row.read(maxId) ?? 0) + 1;
  }
}
