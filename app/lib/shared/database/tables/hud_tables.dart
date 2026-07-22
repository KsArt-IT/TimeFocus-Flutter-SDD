import 'package:drift/drift.dart';

/// Persistent queue of HUD system-action suggestions (schedule time reached,
/// activity started running, toilet suggested). A `SystemAction` appears at
/// most once — a fresh trigger replaces (un-dismisses, refreshes) any
/// existing row for the same action. `day` marks when it was last (re)raised,
/// so rows left over from a previous day can be purged on rollover.
@DataClassName('HudQueueItemModel')
class HudQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get systemAction => text().unique()();
  DateTimeColumn get day => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();
}
