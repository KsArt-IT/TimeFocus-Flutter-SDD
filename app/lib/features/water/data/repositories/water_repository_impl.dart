import 'package:injectable/injectable.dart';

import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/water/data/mappers/water_mappers.dart';
import 'package:timefocus/features/water/domain/entities/day_schedule_times_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_log_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';

@LazySingleton(as: WaterRepository)
class WaterRepositoryImpl with SafeCallMixin implements WaterRepository {
  WaterRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<int> watchDrankToday(DateTime day) =>
      _db.waterDao.watchDrankBetween(day, day.add(const Duration(days: 1)));

  @override
  Stream<List<WaterLogEntity>> watchLogPoints(DateTime from, DateTime to) =>
      _db.waterDao.watchLogsBetween(from, to).map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<Result<WaterLogEntity>> getLog(int id) => safeCall(() async {
    final row = await _db.waterDao.getLogById(id);
    if (row == null) {
      throw const DatabaseFailure('water log not found', code: DatabaseFailure.entityNotFound);
    }
    return row.toEntity();
  });

  @override
  Future<Result<void>> updateLog({
    required int id,
    required int volume,
    required DateTime createdAt,
  }) => voidSafeCall(() => _db.waterDao.updateLog(id, volume: volume, createdAt: createdAt));

  @override
  Future<Result<void>> deleteLog(int id) => voidSafeCall(() => _db.waterDao.deleteLog(id));

  @override
  Stream<WaterSettingsEntity> watchSettings() =>
      _db.waterDao.watchSettings().map((m) => m.toEntity());

  @override
  Future<Result<WaterSettingsEntity>> currentSettings() => safeCall(
    () async => (await _db.waterDao.getSettings()).toEntity(),
  );

  @override
  Future<Result<void>> saveSettings(WaterSettingsEntity settings) => voidSafeCall(
    () => _db.waterDao.saveSettings(settings.toCompanion()),
  );

  @override
  Future<Result<List<int>>> reminderTimes() => safeCall(() => _db.waterDao.reminderTimes());

  @override
  Future<Result<void>> saveReminderTimes(List<int> timesMinutes) => voidSafeCall(
    () => _db.waterDao.replaceReminderTimes(timesMinutes),
  );

  @override
  Stream<List<WaterQuickButtonEntity>> watchQuickButtons() =>
      _db.waterDao.watchQuickButtons().map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Stream<List<WaterQuickButtonEntity>> watchAllQuickButtons() =>
      _db.waterDao.watchAllQuickButtons().map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<Result<void>> saveQuickButton(WaterQuickButtonEntity button) => voidSafeCall(
    () => _db.waterDao.saveQuickButton(button.toCompanion()),
  );

  @override
  Future<Result<void>> deleteQuickButton(int id) => voidSafeCall(
    () => _db.waterDao.deleteQuickButton(id),
  );

  @override
  Future<Result<void>> reorderQuickButtons(List<int> orderedIds) => voidSafeCall(
    () => _db.waterDao.reorderQuickButtons(orderedIds),
  );

  @override
  Future<Result<int>> ensureDailyGoal(DateTime day) => safeCall(() async {
    final existing = await _db.waterDao.goalForDay(day);
    if (existing != null) return existing.goalVolume;
    final settings = await _db.waterDao.getSettings();
    final goal = settings.toEntity().computedGoalMl;
    await _db.waterDao.ensureDailyGoal(day, goal);
    return goal;
  });

  @override
  Future<Result<void>> log(int volume, DateTime now) => voidSafeCall(
    () => _db.waterDao.insertLog(volume, now),
  );

  @override
  Future<Result<DayScheduleTimesEntity>> dayScheduleTimes(DayType dayType) => safeCall(() async {
    final events = await _db.scheduleDao.eventsForDay(dayType.index);
    int? wakeUp;
    int? sleep;
    final meals = <int>[];
    final systemActionTimes = <(SystemAction, int)>[];
    for (final e in events) {
      final type = ScheduleEventType.fromName(e.type);
      switch (type) {
        case ScheduleEventType.wakeUp:
          wakeUp = e.timeMinutes;
        case ScheduleEventType.sleep:
          sleep = e.timeMinutes;
        case ScheduleEventType.meal:
          meals.add(e.timeMinutes);
        default:
          break;
      }
      final action = type.systemAction;
      if (action != null) systemActionTimes.add((action, e.timeMinutes));
    }
    return DayScheduleTimesEntity(
      wakeUpMinutes: wakeUp,
      sleepMinutes: sleep,
      mealTimesMinutes: meals,
      systemActionTimes: systemActionTimes,
    );
  });
}
