import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/history/presentation/cubit/history_cubit.dart';
import 'package:timefocus/features/history/presentation/pages/reports_page.dart';
import 'package:timefocus/features/history/presentation/pages/session_edit_page.dart';
import 'package:timefocus/features/history/presentation/widgets/history_bottom_panel.dart';
import 'package:timefocus/features/history/presentation/widgets/history_header_bar.dart';
import 'package:timefocus/features/history/presentation/widgets/interval_tile.dart';
import 'package:timefocus/features/history/presentation/widgets/total_tile.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/history_mode.dart';

/// US6: history screen — mode/period navigation, header, editable list.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (_) {
        final cubit = getIt<HistoryCubit>();
        unawaited(cubit.subscribe());
        return cubit;
      },
      child: const _HistoryPageContent(),
    );
  }
}

class _HistoryPageContent extends StatelessWidget {
  const _HistoryPageContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: l10n.reportsTitle,
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const ReportsPage()),
            ),
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) => switch (state) {
          HistoryInitial() => const Center(child: CircularProgressIndicator()),
          HistoryError(:final failure) => Center(child: Text(failure.localizedMessage(l10n))),
          HistoryLoaded() => Column(
            children: [
              HistoryHeaderBar(header: state.header),
              const Divider(height: 1),
              Expanded(child: _HistoryList(state: state)),
              HistoryBottomPanel(mode: state.mode, period: state.period),
            ],
          ),
        },
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state});

  final HistoryLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (state.mode) {
      case HistoryMode.intervals:
        if (state.intervals.isEmpty) return Center(child: Text(l10n.historyEmpty));
        return ListView.builder(
          itemCount: state.intervals.length,
          itemBuilder: (context, index) {
            final interval = state.intervals[index];
            return IntervalTile(
              interval: interval,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => SessionEditPage(historyId: interval.historyId)),
              ),
            );
          },
        );
      case HistoryMode.totals:
        if (state.totals.isEmpty) return Center(child: Text(l10n.historyEmpty));
        return ListView.builder(
          itemCount: state.totals.length,
          itemBuilder: (context, index) => TotalTile(total: state.totals[index]),
        );
      case HistoryMode.stats:
        return Center(child: Text(l10n.historyModeStatisticsComingSoon));
    }
  }
}
