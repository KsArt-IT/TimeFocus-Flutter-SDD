import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/settings/domain/entities/user_settings_entity.dart';

abstract interface class UserSettingsRepository {
  Stream<UserSettingsEntity> watch();

  Future<Result<UserSettingsEntity>> get();

  /// Singleton id=1, upsert.
  Future<Result<void>> save(UserSettingsEntity e);
}
