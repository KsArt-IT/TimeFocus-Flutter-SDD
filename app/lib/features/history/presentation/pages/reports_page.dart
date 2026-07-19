import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/history/domain/usecases/report_preset_range_usecase.dart';
import 'package:timefocus/features/history/presentation/cubit/reports_cubit.dart';
import 'package:timefocus/features/history/presentation/widgets/daily_bar_chart.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/ticking_timer.dart';

/// FR-041: 7 period presets + fl_chart charts (time by day, water).
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReportsCubit>(
      create: (_) {
        final cubit = getIt<ReportsCubit>();
        unawaited(cubit.subscribe());
        return cubit;
      },
      child: const _ReportsPageContent(),
    );
  }
}

class _ReportsPageContent extends StatelessWidget {
  const _ReportsPageContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) => switch (state) {
          ReportsLoading() => const Center(child: CircularProgressIndicator()),
          ReportsError(:final failure) => Center(child: Text(failure.localizedMessage(l10n))),
          ReportsLoaded() => Column(
            children: [
              _PresetSelector(selected: state.preset),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DailyBarChart(
                      title: l10n.reportChartTimeByDay,
                      from: state.from,
                      to: state.to,
                      valuesByDay: state.timeByDay,
                      barColor: Theme.of(context).colorScheme.primary,
                      valueLabel: formatDuration,
                    ),
                    const SizedBox(height: 24),
                    DailyBarChart(
                      title: l10n.reportChartWater,
                      from: state.from,
                      to: state.to,
                      valuesByDay: state.waterByDay,
                      barColor: Theme.of(context).colorScheme.secondary,
                      valueLabel: l10n.waterGoalMl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  const _PresetSelector({required this.selected});

  final ReportPreset selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ReportsCubit>();
    final labels = {
      ReportPreset.today: l10n.reportPresetToday,
      ReportPreset.yesterday: l10n.reportPresetYesterday,
      ReportPreset.thisWeek: l10n.reportPresetThisWeek,
      ReportPreset.lastWeek: l10n.reportPresetLastWeek,
      ReportPreset.thisMonth: l10n.reportPresetThisMonth,
      ReportPreset.lastMonth: l10n.reportPresetLastMonth,
      ReportPreset.last30Days: l10n.reportPresetLast30Days,
    };
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          for (final preset in ReportPreset.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(labels[preset]!),
                selected: preset == selected,
                onSelected: (_) => cubit.setPreset(preset),
              ),
            ),
        ],
      ),
    );
  }
}
