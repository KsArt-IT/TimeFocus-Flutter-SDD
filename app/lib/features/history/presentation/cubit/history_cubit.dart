import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/history/domain/entities/history_header_entity.dart';
import 'package:timefocus/features/history/domain/repositories/history_repository.dart';
import 'package:timefocus/features/history/domain/usecases/history_period_range_usecase.dart';
import 'package:timefocus/features/history/presentation/cubit/history_state.dart';
import 'package:timefocus/shared/enums/history_mode.dart';
import 'package:timefocus/shared/enums/history_period.dart';

export 'package:timefocus/features/history/presentation/cubit/history_state.dart';

/// Screen-scoped cubit for HistoryPage (contracts/blocs.md): mode/period/
/// anchor navigation with a reactive list per mode (FR-038).
@injectable
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository) : super(const HistoryState.initial());

  final HistoryRepository _repository;

  HistoryMode _mode = HistoryMode.intervals;
  HistoryPeriod _period = HistoryPeriod.day;
  DateTime _anchor = DateTime.now();

  StreamSubscription<void>? _sub;

  Future<void> subscribe({HistoryMode initialMode = .intervals}) {
    _mode = initialMode;
    return _reload();
  }

  void setMode(HistoryMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    unawaited(_reload());
  }

  void setPeriod(HistoryPeriod period) {
    if (period == _period) return;
    _period = period;
    unawaited(_reload());
  }

  void stepPrevious() {
    _anchor = historyStepAnchor(_period, _anchor, forward: false);
    unawaited(_reload());
  }

  void stepNext() {
    _anchor = historyStepAnchor(_period, _anchor, forward: true);
    unawaited(_reload());
  }

  void goToToday() {
    _anchor = DateTime.now();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    await _sub?.cancel();
    final (from, to) = historyPeriodRange(_period, _anchor);

    final headerResult = await _repository.header(from, to);
    if (isClosed) return;
    headerResult.map(
      success: (header) => subscribeByMode(from, to, header),
      failure: (error) => emit(HistoryState.error(error)),
    );
  }

  void subscribeByMode(DateTime from, DateTime to, HistoryHeaderEntity header) {
    switch (_mode) {
      case HistoryMode.intervals:
        _sub = _repository
            .watchIntervals(from, to)
            .listen(
              (items) => emit(
                HistoryState.loaded(
                  mode: _mode,
                  period: _period,
                  anchor: _anchor,
                  header: header,
                  intervals: items,
                ),
              ),
              onError: (Object e) => logger.e('history intervals stream error', error: e),
            );
      case HistoryMode.totals:
        _sub = _repository
            .watchTotals(from, to)
            .listen(
              (items) => emit(
                HistoryState.loaded(
                  mode: _mode,
                  period: _period,
                  anchor: _anchor,
                  header: header,
                  totals: items,
                ),
              ),
              onError: (Object e) => logger.e('history totals stream error', error: e),
            );
      case HistoryMode.stats:
        // Statistics mode is a documented "coming soon" placeholder (see
        // historyModeStatisticsComingSoon) — only the header is meaningful.
        emit(
          HistoryState.loaded(mode: _mode, period: _period, anchor: _anchor, header: header),
        );
      case HistoryMode.water:
        _sub = _repository
            .watchWaterLogs(from, to)
            .listen(
              (items) => emit(
                HistoryState.loaded(
                  mode: _mode,
                  period: _period,
                  anchor: _anchor,
                  header: header,
                  waterLogs: items,
                ),
              ),
              onError: (Object e) => logger.e('history water logs stream error', error: e),
            );
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
