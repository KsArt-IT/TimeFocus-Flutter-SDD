import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/features/history/presentation/cubit/history_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/history_mode.dart';
import 'package:timefocus/shared/enums/history_period.dart';

/// Bottom panel (FR-038): mode tabs, period tabs, and prev/today/next
/// navigation arrows.
class HistoryBottomPanel extends StatelessWidget {
  const HistoryBottomPanel({required this.mode, required this.period, super.key});

  final HistoryMode mode;
  final HistoryPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<HistoryCubit>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<HistoryMode>(
              segments: [
                ButtonSegment(value: HistoryMode.intervals, label: Text(l10n.historyModeIntervals)),
                ButtonSegment(
                  value: HistoryMode.totals,
                  label: Text(l10n.historyModeTotalByAction),
                ),
                ButtonSegment(value: HistoryMode.stats, label: Text(l10n.historyModeStatistics)),
              ],
              selected: {mode},
              onSelectionChanged: (s) => cubit.setMode(s.first),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: cubit.stepPrevious,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: SegmentedButton<HistoryPeriod>(
                    segments: [
                      ButtonSegment(value: HistoryPeriod.day, label: Text(l10n.periodDay)),
                      ButtonSegment(value: HistoryPeriod.week, label: Text(l10n.periodWeek)),
                      ButtonSegment(value: HistoryPeriod.month, label: Text(l10n.periodMonth)),
                      ButtonSegment(value: HistoryPeriod.year, label: Text(l10n.periodYear)),
                    ],
                    selected: {period},
                    onSelectionChanged: (s) => cubit.setPeriod(s.first),
                  ),
                ),
                IconButton(
                  onPressed: cubit.stepNext,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            TextButton(
              onPressed: cubit.goToToday,
              child: Text(l10n.historyBackToToday),
            ),
          ],
        ),
      ),
    );
  }
}
