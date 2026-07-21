import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/features/history/domain/entities/history_header_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_total_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_log_entity.dart';
import 'package:timefocus/shared/enums/history_mode.dart';
import 'package:timefocus/shared/enums/history_period.dart';

part 'history_state.freezed.dart';

@freezed
sealed class HistoryState with _$HistoryState {
  const factory HistoryState.initial() = HistoryInitial;

  const factory HistoryState.loaded({
    required HistoryMode mode,
    required HistoryPeriod period,
    required DateTime anchor,
    required HistoryHeaderEntity header,
    @Default(<HistoryIntervalEntity>[]) List<HistoryIntervalEntity> intervals,
    @Default(<HistoryTotalEntity>[]) List<HistoryTotalEntity> totals,
    @Default(<WaterLogEntity>[]) List<WaterLogEntity> waterLogs,
  }) = HistoryLoaded;

  const factory HistoryState.error(AppFailure failure) = HistoryError;
}
