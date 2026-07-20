import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/utils/time_guard.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/shared/enums/action_status.dart';

part 'running_with_name_entity.freezed.dart';

/// A running activity joined with its dictionary entry.
@freezed
abstract class RunningWithNameEntity with _$RunningWithNameEntity {
  const RunningWithNameEntity._();

  const factory RunningWithNameEntity({
    required int runningId,
    required int historyId,
    required ActionNameEntity action,
    required ActionStatus status,
    required DateTime startedAt,
    DateTime? pausedAt,
    @Default(0) int accumulatedSec,
    @Default(false) bool pausedBySystem,
  }) = _RunningWithNameEntity;

  bool get isActive => status == ActionStatus.active;

  /// Timer invariant: elapsed = accumulated + (active ? now − startedAt : 0).
  /// Clamped ≥ 0 to survive system clock changes.
  int elapsedSec(DateTime now) {
    final live = isActive ? now.secondsSince(startedAt) : 0;
    final total = accumulatedSec + live;
    return total < 0 ? 0 : total;
  }
}
