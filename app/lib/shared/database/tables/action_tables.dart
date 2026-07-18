import 'package:drift/drift.dart';

/// Activity dictionary (system + user activities and groups).
@DataClassName('ActionNameModel')
class ActionNames extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  IntColumn get color => integer()();
  IntColumn get icon => integer()();
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();
  IntColumn get groupId => integer().nullable().references(ActionNames, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get mode => integer().withDefault(const Constant(0))();
  IntColumn get pomodoroType => integer().nullable()();
  IntColumn get breakActionId => integer().nullable().references(ActionNames, #id)();
  BoolColumn get pauseOthers => boolean().withDefault(const Constant(false))();
  IntColumn get defaultDurationSec => integer().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get hudPriority => integer().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// Currently running activity instances.
@DataClassName('ActionRunningModel')
class ActionRunnings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get actionNameId =>
      integer().references(ActionNames, #id, onDelete: KeyAction.cascade)();
  IntColumn get actionHistoryId => integer().references(ActionHistories, #id)();
  IntColumn get status => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  IntColumn get accumulatedSec => integer().withDefault(const Constant(0))();
  BoolColumn get pausedBySystem => boolean().withDefault(const Constant(false))();
}

/// One activity per day of session start.
@DataClassName('ActionHistorieModel')
class ActionHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get actionNameId =>
      integer().references(ActionNames, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  TextColumn get comment => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {actionNameId, date},
  ];
}

/// Time intervals belonging to a history record.
@DataClassName('ActionHistoryIntervalModel')
class ActionHistoryIntervals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get actionHistoryId =>
      integer().references(ActionHistories, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime()();
}
