import 'package:injectable/injectable.dart';

import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';

/// Logs a drink: fixes today's goal on first log of the day (data-model.md —
/// DailyWaterGoals), then inserts the entry and updates lastDrankAt.
/// Interval-mode reminder replanning and the toilet trigger are driven by
/// HudCubit, which owns the notification text (l10n needs the widget tree).
@injectable
class LogWaterUseCase {
  LogWaterUseCase(this._water);

  final WaterRepository _water;

  Future<Result<void>> call(int volume, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final day = DateTime.utc(at.year, at.month, at.day);
    final goalResult = await _water.ensureDailyGoal(day);
    if (goalResult.isFailure) return Result.failure(goalResult.errorOrNull!);
    return _water.log(volume, at);
  }
}
