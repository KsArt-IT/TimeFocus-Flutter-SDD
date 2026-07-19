import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/features/history/domain/repositories/history_repository.dart';
import 'package:timefocus/features/history/domain/usecases/report_preset_range_usecase.dart';
import 'package:timefocus/features/history/presentation/cubit/reports_state.dart';

export 'package:timefocus/features/history/presentation/cubit/reports_state.dart';

/// Screen-scoped cubit for ReportsPage (FR-041): 7 period presets, time and
/// water totals by day for the charts.
@injectable
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._history) : super(const ReportsState.loading());

  final HistoryRepository _history;

  Future<void> subscribe() => setPreset(ReportPreset.today);

  Future<void> setPreset(ReportPreset preset) async {
    final (from, to) = reportPresetRange(preset, DateTime.now());
    final timeResult = await _history.totalsByDay(from, to);
    if (isClosed) return;
    final waterResult = await _history.waterByDay(from, to);
    if (isClosed) return;

    final time = timeResult.valueOrNull;
    final water = waterResult.valueOrNull;
    if (time == null || water == null) {
      emit(ReportsState.error(timeResult.errorOrNull ?? waterResult.errorOrNull!));
      return;
    }
    emit(
      ReportsState.loaded(preset: preset, from: from, to: to, timeByDay: time, waterByDay: water),
    );
  }
}
