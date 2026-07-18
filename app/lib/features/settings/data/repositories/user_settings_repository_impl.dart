import 'package:injectable/injectable.dart';
import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/settings/data/mappers/user_settings_mapper.dart';
import 'package:timefocus/features/settings/domain/entities/user_settings_entity.dart';
import 'package:timefocus/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';

@LazySingleton(as: UserSettingsRepository)
class UserSettingsRepositoryImpl with SafeCallMixin implements UserSettingsRepository {
  UserSettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<UserSettingsEntity> watch() => _db.settingsDao.watch().map((row) => row.toEntity());

  @override
  Future<Result<UserSettingsEntity>> get() async => safeCall(() async {
    final row = await _db.settingsDao.get();
    return row.toEntity();
  });

  @override
  Future<Result<void>> save(UserSettingsEntity e) async => voidSafeCall(() async {
    await _db.settingsDao.save(e.toCompanion());
  });
}
