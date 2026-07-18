import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/shared/enums/pomodoro_after_action.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

part 'pomodoro_settings_entity.freezed.dart';

/// Versioned Pomodoro settings snapshot (data-model.md — PomodoroSettings).
/// Every change is a new row; sessions reference the row active at start
/// time, so past statistics are never rewritten.
@freezed
abstract class PomodoroSettingsEntity with _$PomodoroSettingsEntity {
  const PomodoroSettingsEntity._();

  const factory PomodoroSettingsEntity({
    required DateTime createdAt,
    @Default(0) int id,
    @Default(AppConstants.pomodoroShortWorkSec) int shortWorkTime,
    @Default(AppConstants.pomodoroNormalWorkSec) int normalWorkTime,
    @Default(AppConstants.pomodoroLongWorkSec) int longWorkTime,
    @Default(AppConstants.pomodoroShortBreakSec) int shortBreakTime,
    @Default(AppConstants.pomodoroLongBreakSec) int longBreakTime,
    @Default(AppConstants.defaultCyclesBeforeLongBreak) int cyclesBeforeLongBreak,
    @Default(false) bool escalateIntervals,
    @Default(PomodoroAfterAction.doNothing) PomodoroAfterAction afterAction,
    @Default(true) bool soundEnabled,
    @Default(true) bool vibrationEnabled,
    @Default(true) bool notificationEnabled,
  }) = _PomodoroSettingsEntity;

  /// Work interval length for [type] (FR-013).
  int workTimeFor(PomodoroType type) => switch (type) {
    PomodoroType.short => shortWorkTime,
    PomodoroType.normal => normalWorkTime,
    PomodoroType.long => longWorkTime,
  };

  /// Break length: long after [cyclesBeforeLongBreak] work intervals (FR-014).
  int breakTimeFor({required bool isLong}) => isLong ? longBreakTime : shortBreakTime;
}
