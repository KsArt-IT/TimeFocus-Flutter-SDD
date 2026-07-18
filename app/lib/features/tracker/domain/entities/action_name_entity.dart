import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

part 'action_name_entity.freezed.dart';

/// Activity dictionary entry (domain, no Drift imports).
@freezed
abstract class ActionNameEntity with _$ActionNameEntity {
  const factory ActionNameEntity({
    required int id,
    required String name,
    required int color,
    required int icon,
    String? description,
    @Default(false) bool isGroup,
    int? groupId,
    @Default(0) int sortOrder,
    @Default(ActionMode.nothing) ActionMode mode,
    PomodoroType? pomodoroType,
    int? breakActionId,
    @Default(false) bool pauseOthers,
    int? defaultDurationSec,
    @Default(false) bool isSystem,
    int? hudPriority,
    @Default(false) bool archived,
  }) = _ActionNameEntity;
}
