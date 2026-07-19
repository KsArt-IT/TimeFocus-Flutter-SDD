import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/features/history/domain/usecases/report_preset_range_usecase.dart';

part 'reports_state.freezed.dart';

@freezed
sealed class ReportsState with _$ReportsState {
  const factory ReportsState.loading() = ReportsLoading;

  const factory ReportsState.loaded({
    required ReportPreset preset,
    required DateTime from,
    required DateTime to,
    required Map<DateTime, int> timeByDay,
    required Map<DateTime, int> waterByDay,
  }) = ReportsLoaded;

  const factory ReportsState.error(AppFailure failure) = ReportsError;
}
