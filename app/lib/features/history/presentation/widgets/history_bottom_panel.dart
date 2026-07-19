import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:timefocus/features/history/presentation/cubit/history_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/history_mode.dart';
import 'package:timefocus/shared/enums/history_period.dart';

/// Bottom panel (FR-038), one compact row: mode icon (tap → picker), prev
/// arrow, current period label (tap → period picker), next arrow, today.
class HistoryBottomPanel extends StatelessWidget {
  const HistoryBottomPanel({
    required this.mode,
    required this.period,
    required this.anchor,
    super.key,
  });

  final HistoryMode mode;
  final HistoryPeriod period;
  final DateTime anchor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<HistoryCubit>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            PopupMenuButton<HistoryMode>(
              tooltip: _modeLabel(l10n, mode),
              icon: Icon(_modeIcon(mode)),
              onSelected: cubit.setMode,
              itemBuilder: (context) => [
                for (final m in HistoryMode.values)
                  PopupMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        Icon(_modeIcon(m), size: 20),
                        const SizedBox(width: 12),
                        Text(_modeLabel(l10n, m)),
                      ],
                    ),
                  ),
              ],
            ),
            IconButton(
              onPressed: cubit.stepPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: PopupMenuButton<HistoryPeriod>(
                tooltip: '',
                onSelected: cubit.setPeriod,
                itemBuilder: (context) => [
                  for (final p in HistoryPeriod.values)
                    PopupMenuItem(value: p, child: Text(_periodLabel(l10n, p))),
                ],
                child: Center(
                  child: Text(
                    _formatAnchor(l10n, period, anchor),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: cubit.stepNext,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              onPressed: cubit.goToToday,
              tooltip: l10n.historyBackToToday,
              icon: const Icon(Icons.today_outlined),
            ),
          ],
        ),
      ),
    );
  }

  IconData _modeIcon(HistoryMode mode) => switch (mode) {
    HistoryMode.intervals => Icons.view_agenda_outlined,
    HistoryMode.totals => Icons.summarize_outlined,
    HistoryMode.stats => Icons.insights_outlined,
  };

  String _modeLabel(AppLocalizations l10n, HistoryMode mode) => switch (mode) {
    HistoryMode.intervals => l10n.historyModeIntervals,
    HistoryMode.totals => l10n.historyModeTotalByAction,
    HistoryMode.stats => l10n.historyModeStatistics,
  };

  String _periodLabel(AppLocalizations l10n, HistoryPeriod period) => switch (period) {
    HistoryPeriod.day => l10n.periodDay,
    HistoryPeriod.week => l10n.periodWeek,
    HistoryPeriod.month => l10n.periodMonth,
    HistoryPeriod.year => l10n.periodYear,
  };

  String _formatAnchor(AppLocalizations l10n, HistoryPeriod period, DateTime anchor) {
    final locale = l10n.localeName;
    switch (period) {
      case HistoryPeriod.day:
        return DateFormat.yMMMMd(locale).format(anchor);
      case HistoryPeriod.week:
        final monday = anchor.subtract(Duration(days: anchor.weekday - DateTime.monday));
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormat.MMMd(locale).format(monday)} – ${DateFormat.MMMd(locale).format(sunday)}';
      case HistoryPeriod.month:
        return DateFormat.yMMMM(locale).format(anchor);
      case HistoryPeriod.year:
        return DateFormat.y(locale).format(anchor);
    }
  }
}
