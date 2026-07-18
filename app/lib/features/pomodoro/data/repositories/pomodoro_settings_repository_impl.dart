import 'package:injectable/injectable.dart';
import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/pomodoro/data/mappers/pomodoro_mappers.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_settings_entity.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_settings_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';

@LazySingleton(as: PomodoroSettingsRepository)
class PomodoroSettingsRepositoryImpl with SafeCallMixin implements PomodoroSettingsRepository {
  PomodoroSettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<PomodoroSettingsEntity>> current() => safeCall(
    () async => (await _db.pomodoroDao.currentSettings()).toEntity(),
  );

  @override
  Future<Result<int>> saveNewVersion(PomodoroSettingsEntity e) => safeCall(
    () => _db.pomodoroDao.insertSettings(e.toCompanion()),
  );

  @override
  Stream<PomodoroSettingsEntity> watch() => _db.pomodoroDao.watchSettings().map(
    (m) => m.toEntity(),
  );
}
