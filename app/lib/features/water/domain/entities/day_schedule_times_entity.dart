import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/constants/system_actions.dart';

part 'day_schedule_times_entity.freezed.dart';

/// Minutes-from-midnight schedule anchors needed by water reminder planning
/// and the HUD norm-by-now interpolation (data-model.md — ScheduleEvents).
@freezed
abstract class DayScheduleTimesEntity with _$DayScheduleTimesEntity {
  const factory DayScheduleTimesEntity({
    int? wakeUpMinutes,
    int? sleepMinutes,
    @Default(<int>[]) List<int> mealTimesMinutes,
    @Default(<(SystemAction, int)>[]) List<(SystemAction, int)> systemActionTimes,
  }) = _DayScheduleTimesEntity;
}
