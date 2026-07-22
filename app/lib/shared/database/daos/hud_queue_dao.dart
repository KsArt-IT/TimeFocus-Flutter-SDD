import 'package:drift/drift.dart';

import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/tables/hud_tables.dart';

part 'hud_queue_dao.g.dart';

@DriftAccessor(tables: [HudQueueItems])
class HudQueueDao extends DatabaseAccessor<AppDatabase> with _$HudQueueDaoMixin {
  HudQueueDao(super.attachedDatabase);

  Stream<List<HudQueueItemModel>> watchActive(DateTime day) =>
      (select(hudQueueItems)
            ..where((t) => t.day.equals(day) & t.dismissed.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  /// Raises [systemAction] for [day]: inserts it, or refreshes (un-dismisses)
  /// it if it's already the queue's row for that action. Conflicts are
  /// detected on `systemAction` (its unique constraint), not the primary key.
  Future<void> upsert(String systemAction, DateTime day, DateTime now) {
    final entry = HudQueueItemsCompanion.insert(
      systemAction: systemAction,
      day: day,
      createdAt: now,
      dismissed: const Value(false),
    );
    return into(hudQueueItems).insert(
      entry,
      onConflict: DoUpdate((_) => entry, target: [hudQueueItems.systemAction]),
    );
  }

  Future<void> dismiss(int id) => (update(hudQueueItems)..where((t) => t.id.equals(id))).write(
    const HudQueueItemsCompanion(dismissed: Value(true)),
  );

  /// Drops rows left over from a previous day (called once on subscribe).
  Future<void> deleteNotToday(DateTime today) =>
      (delete(hudQueueItems)..where((t) => t.day.equals(today).not())).go();
}
