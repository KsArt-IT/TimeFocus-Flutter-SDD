import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_interval_edit.freezed.dart';

/// Whether a saved interval overlapped another one of the same activity
/// (FR-040: overlap is only a warning, the save still goes through).
enum OverlapCheck { ok, warning }

/// Input to HistoryRepository.saveInterval — [id] null means "add a new
/// interval to [historyId]".
@freezed
abstract class HistoryIntervalEdit with _$HistoryIntervalEdit {
  const factory HistoryIntervalEdit({
    required int historyId,
    required DateTime startedAt,
    required DateTime finishedAt,
    int? id,
  }) = _HistoryIntervalEdit;
}
