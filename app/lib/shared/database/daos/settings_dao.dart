import 'package:drift/drift.dart';

import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/tables/app_tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [UserSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  static const int _singletonId = 1;

  Stream<UserSettingModel> watch() =>
      (select(userSettings)..where((t) => t.id.equals(_singletonId))).watchSingle();

  Future<UserSettingModel> get() =>
      (select(userSettings)..where((t) => t.id.equals(_singletonId))).getSingle();

  Future<void> save(UserSettingsCompanion companion) =>
      (update(userSettings)..where((t) => t.id.equals(_singletonId))).write(companion);
}
