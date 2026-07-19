import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/features/schedule/domain/entities/timeline_item.dart';
import 'package:timefocus/shared/enums/day_type.dart';

part 'schedule_state.freezed.dart';

@freezed
sealed class ScheduleState with _$ScheduleState {
  const factory ScheduleState.initial() = ScheduleInitial;

  const factory ScheduleState.loaded({
    required List<TimelineItem> timeline,
    required DayType dayType,
  }) = ScheduleLoaded;

  const factory ScheduleState.error(AppFailure failure) = ScheduleError;
}
