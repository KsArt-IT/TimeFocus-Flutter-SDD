import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_interval_entity.freezed.dart';

/// One tracked interval joined with its activity, for the "Intervals" mode
/// list (FR-038).
@freezed
abstract class HistoryIntervalEntity with _$HistoryIntervalEntity {
  const factory HistoryIntervalEntity({
    required int intervalId,
    required int historyId,
    required int actionNameId,
    required String actionName,
    required bool isSystemAction,
    required int color,
    required int icon,
    required DateTime startedAt,
    required DateTime finishedAt,
  }) = _HistoryIntervalEntity;
}
