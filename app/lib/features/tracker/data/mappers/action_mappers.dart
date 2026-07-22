import 'package:drift/drift.dart';

import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/daos/running_dao.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/action_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

extension ActionNameModelMapper on ActionNameModel {
  ActionNameEntity toEntity() => ActionNameEntity(
    id: id,
    name: name,
    description: description,
    color: color,
    icon: icon,
    isGroup: isGroup,
    groupId: groupId,
    sortOrder: sortOrder,
    mode: ActionMode.fromIndex(mode),
    pomodoroType: pomodoroType == null ? null : PomodoroType.fromIndex(pomodoroType!),
    breakActionId: breakActionId,
    pauseOthers: pauseOthers,
    defaultDurationSec: defaultDurationSec,
    isSystem: isSystem,
    archived: archived,
  );
}

extension ActionNameEntityMapper on ActionNameEntity {
  ActionNamesCompanion toCompanion({bool includeId = true}) => ActionNamesCompanion(
    id: includeId && id != 0 ? Value(id) : const Value.absent(),
    name: Value(name),
    description: Value(description),
    color: Value(color),
    icon: Value(icon),
    isGroup: Value(isGroup),
    groupId: Value(groupId),
    sortOrder: Value(sortOrder),
    mode: Value(mode.index),
    pomodoroType: Value(pomodoroType?.index),
    breakActionId: Value(breakActionId),
    pauseOthers: Value(pauseOthers),
    defaultDurationSec: Value(defaultDurationSec),
    isSystem: Value(isSystem),
    archived: Value(archived),
  );
}

extension RunningWithNameMapper on RunningWithName {
  RunningWithNameEntity toEntity() => RunningWithNameEntity(
    runningId: running.id,
    historyId: running.actionHistoryId,
    action: name.toEntity(),
    status: ActionStatus.fromIndex(running.status),
    startedAt: running.startedAt,
    pausedAt: running.pausedAt,
    accumulatedSec: running.accumulatedSec,
    pausedBySystem: running.pausedBySystem,
  );
}
