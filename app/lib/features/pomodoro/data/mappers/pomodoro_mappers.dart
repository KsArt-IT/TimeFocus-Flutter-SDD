import 'package:drift/drift.dart';

import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_session_entity.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_settings_entity.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/pomodoro_after_action.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

extension PomodoroSessionModelMapper on PomodoroSessionModel {
  PomodoroSessionEntity toEntity() => PomodoroSessionEntity(
    id: id,
    actionNameId: actionNameId,
    actionHistoryId: actionHistoryId,
    settingsId: settingsId,
    type: PomodoroType.fromIndex(type),
    plannedTime: plannedTime,
    actualTime: actualTime,
    startTime: startTime,
    endTime: endTime,
    status: PomodoroStatus.fromIndex(status),
    cycleNumber: cycleNumber,
  );
}

extension PomodoroSessionEntityMapper on PomodoroSessionEntity {
  PomodoroSessionsCompanion toCompanion() => PomodoroSessionsCompanion(
    actionNameId: Value(actionNameId),
    actionHistoryId: Value(actionHistoryId),
    settingsId: Value(settingsId),
    type: Value(type.index),
    plannedTime: Value(plannedTime),
    actualTime: Value(actualTime),
    startTime: Value(startTime),
    endTime: Value(endTime),
    status: Value(status.index),
    cycleNumber: Value(cycleNumber),
  );
}

extension PomodoroSettingModelMapper on PomodoroSettingModel {
  PomodoroSettingsEntity toEntity() => PomodoroSettingsEntity(
    id: id,
    shortWorkTime: shortWorkTime,
    normalWorkTime: normalWorkTime,
    longWorkTime: longWorkTime,
    shortBreakTime: shortBreakTime,
    longBreakTime: longBreakTime,
    cyclesBeforeLongBreak: cyclesBeforeLongBreak,
    escalateIntervals: escalateIntervals,
    afterAction: PomodoroAfterAction.fromIndex(afterAction),
    soundEnabled: soundEnabled,
    vibrationEnabled: vibrationEnabled,
    notificationEnabled: notificationEnabled,
    createdAt: createdAt,
  );
}

extension PomodoroSettingsEntityMapper on PomodoroSettingsEntity {
  PomodoroSettingsCompanion toCompanion() => PomodoroSettingsCompanion(
    shortWorkTime: Value(shortWorkTime),
    normalWorkTime: Value(normalWorkTime),
    longWorkTime: Value(longWorkTime),
    shortBreakTime: Value(shortBreakTime),
    longBreakTime: Value(longBreakTime),
    cyclesBeforeLongBreak: Value(cyclesBeforeLongBreak),
    escalateIntervals: Value(escalateIntervals),
    afterAction: Value(afterAction.index),
    soundEnabled: Value(soundEnabled),
    vibrationEnabled: Value(vibrationEnabled),
    notificationEnabled: Value(notificationEnabled),
    createdAt: Value(createdAt),
  );
}
