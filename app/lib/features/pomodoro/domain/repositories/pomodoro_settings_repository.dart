import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_settings_entity.dart';

abstract interface class PomodoroSettingsRepository {
  /// Latest settings row.
  Future<Result<PomodoroSettingsEntity>> current();

  /// Every change is a new row — past sessions keep referencing the old one.
  Future<Result<int>> saveNewVersion(PomodoroSettingsEntity e);

  Stream<PomodoroSettingsEntity> watch();
}
