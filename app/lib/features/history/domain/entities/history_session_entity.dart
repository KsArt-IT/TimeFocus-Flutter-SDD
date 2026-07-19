import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_session_entity.freezed.dart';

/// One interval as shown/edited on the session screen.
@freezed
abstract class HistoryIntervalEditEntity with _$HistoryIntervalEditEntity {
  const factory HistoryIntervalEditEntity({
    required int id,
    required DateTime startedAt,
    required DateTime finishedAt,
  }) = _HistoryIntervalEditEntity;
}

/// Full session detail (FR-040): activity + comment + all its intervals.
@freezed
abstract class HistorySessionEntity with _$HistorySessionEntity {
  const factory HistorySessionEntity({
    required int historyId,
    required int actionNameId,
    required DateTime date,
    String? comment,
    @Default(<HistoryIntervalEditEntity>[]) List<HistoryIntervalEditEntity> intervals,
  }) = _HistorySessionEntity;
}
