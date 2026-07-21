import 'package:drift/drift.dart';

import 'package:timefocus/core/constants/app_constants.dart';

/// Mirror of scheduled local notifications (id == plugin notificationId).
@DataClassName('NotificationModel')
class Notifications extends Table {
  IntColumn get id => integer()();
  IntColumn get type => integer()();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get payload => text()();
  BoolColumn get isDelivered => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Singleton (id=1) user settings.
@DataClassName('UserSettingModel')
class UserSettings extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withDefault(const Constant(''))();
  IntColumn get columnCount =>
      integer().withDefault(const Constant(AppConstants.defaultGridColumns))();
  IntColumn get rowCount => integer().withDefault(const Constant(AppConstants.defaultGridRows))();
  BoolColumn get rowCountAdaptive => boolean().withDefault(const Constant(true))();
  IntColumn get themeMode => integer().withDefault(const Constant(2))();
  TextColumn get language => text().withDefault(const Constant('system'))();
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get onboardingCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get timeFormat => integer().withDefault(const Constant(1))();
  BoolColumn get isShortTime => boolean().withDefault(const Constant(false))();
  BoolColumn get reminderRequest => boolean().withDefault(const Constant(false))();
  BoolColumn get isReminder => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
