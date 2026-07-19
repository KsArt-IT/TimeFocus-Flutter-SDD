import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_schedule_times_entity.freezed.dart';

/// Minutes-from-midnight schedule anchors needed by water reminder planning
/// and the HUD norm-by-now interpolation (data-model.md — ScheduleEvents).
@freezed
abstract class DayScheduleTimesEntity with _$DayScheduleTimesEntity {
  const factory DayScheduleTimesEntity({
    int? wakeUpMinutes,
    int? sleepMinutes,
    @Default(<int>[]) List<int> mealTimesMinutes,
  }) = _DayScheduleTimesEntity;
}
