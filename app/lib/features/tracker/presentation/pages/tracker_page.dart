import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/features/tracker/presentation/widgets/action_grid.dart';
import 'package:timefocus/features/tracker/presentation/widgets/confirm_interrupt_dialog.dart';
import 'package:timefocus/features/tracker/presentation/widgets/running_card.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// US1: running cards with timers on top, activity grid below.
class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<ActionBloc, ActionState>(
      listenWhen: (previous, current) =>
          current is ActionLoaded && current.pendingConfirmation != null,
      listener: (context, state) async {
        final pending = (state as ActionLoaded).pendingConfirmation;
        if (pending == null) return;
        final bloc = context.read<ActionBloc>();
        final confirmed = await showConfirmInterruptDialog(context, pending);
        if (confirmed) {
          bloc.add(ActionEvent.startConfirmed(pending.id));
        } else {
          bloc.add(const ActionEvent.startCancelled());
        }
      },
      builder: (context, state) {
        return switch (state) {
          ActionInitial() || ActionLoading() => const Center(child: CircularProgressIndicator()),
          ActionError(:final failure) => Center(child: Text(failure.localizedMessage(l10n))),
          ActionLoaded(:final running, :final grid, :final currentGroupId, :final todayTotals) =>
            Column(
              children: [
                if (running.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.noRunningActions,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: running.length,
                      itemBuilder: (context, index) {
                        final r = running[index];
                        return RunningCard(
                          key: ValueKey(r.runningId),
                          running: r,
                          todayTotalSec: todayTotals[r.action.id] ?? 0,
                        );
                      },
                    ),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
                    buildWhen: (p, c) => p.settings.columnCount != c.settings.columnCount,
                    builder: (context, settings) => ActionGrid(
                      actions: grid,
                      columns: settings.settings.columnCount,
                      currentGroupId: currentGroupId,
                    ),
                  ),
                ),
              ],
            ),
        };
      },
    );
  }
}
