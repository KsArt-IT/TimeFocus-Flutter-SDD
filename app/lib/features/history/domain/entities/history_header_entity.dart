import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_header_entity.freezed.dart';

/// History screen header (FR-039): total tracked time excluding Sleep,
/// Pomodoro completed/interrupted counts, water drunk/goal — all for the
/// currently selected period.
@freezed
abstract class HistoryHeaderEntity with _$HistoryHeaderEntity {
  const factory HistoryHeaderEntity({
    @Default(0) int totalSec,
    @Default(0) int pomodoroCompleted,
    @Default(0) int pomodoroInterrupted,
    @Default(0) int waterDrankMl,
    @Default(0) int waterGoalMl,
  }) = _HistoryHeaderEntity;
}
