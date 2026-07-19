import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_total_entity.freezed.dart';

/// Per-activity aggregate for the "Summary" mode list (FR-038).
@freezed
abstract class HistoryTotalEntity with _$HistoryTotalEntity {
  const factory HistoryTotalEntity({
    required int actionNameId,
    required String actionName,
    required bool isSystemAction,
    required int color,
    required int icon,
    required int totalSec,
    required int sessions,
  }) = _HistoryTotalEntity;
}
