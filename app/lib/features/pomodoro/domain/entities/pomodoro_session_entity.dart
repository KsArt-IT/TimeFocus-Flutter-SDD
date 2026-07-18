import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/shared/enums/pomodoro_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

part 'pomodoro_session_entity.freezed.dart';

/// A single Pomodoro work/break interval, snapshot of the settings that
/// governed it (data-model.md — PomodoroSessions).
@freezed
abstract class PomodoroSessionEntity with _$PomodoroSessionEntity {
  const factory PomodoroSessionEntity({
    required int id,
    required int settingsId,
    required PomodoroType type,
    required int plannedTime,
    required DateTime startTime,
    int? actionNameId,
    int? actionHistoryId,
    @Default(0) int actualTime,
    DateTime? endTime,
    @Default(PomodoroStatus.active) PomodoroStatus status,
    @Default(1) int cycleNumber,
  }) = _PomodoroSessionEntity;
}
