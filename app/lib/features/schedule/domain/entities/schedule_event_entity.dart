import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/meal_slot.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';

part 'schedule_event_entity.freezed.dart';

/// Day schedule event (data-model.md — ScheduleEvents): plan blocks for
/// weekdays/weekend (dayType), optionally strict (forces a Pomodoro
/// interruption at the exact time, FR-031/032).
@freezed
abstract class ScheduleEventEntity with _$ScheduleEventEntity {
  const factory ScheduleEventEntity({
    required ScheduleEventType type,
    required int timeMinutes,
    @Default(0) int id,
    MealSlot? mealSubtype,
    @Default(AppConstants.defaultScheduleEventDurationMin) int durationMinutes,
    @Default(false) bool isStrictly,
    int? warningMinutes,
    int? actionId,
    @Default(true) bool isEnabled,
    @Default(0) int sortOrder,
    @Default(DayType.weekday) DayType dayType,
  }) = _ScheduleEventEntity;
}
