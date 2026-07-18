import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/features/tracker/presentation/widgets/action_grid.dart';
import 'package:timefocus/features/tracker/presentation/widgets/confirm_interrupt_dialog.dart';
import 'package:timefocus/features/tracker/presentation/widgets/running_actions_list.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// US1: running cards with timers on top, activity grid below.
class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<ActionBloc, ActionState>(
      listenWhen: (previous, current) => current.maybeMap(
        loaded: (s) => s.pendingConfirmation != null,
        orElse: () => false,
      ),
      listener: (context, state) async {
        final pending = state.mapOrNull(loaded: (s) => s.pendingConfirmation);
        if (pending == null) return;
        final bloc = context.read<ActionBloc>();
        final confirmed = await showConfirmInterruptDialog(context, pending);
        if (confirmed) {
          bloc.add(ActionEvent.startConfirmed(pending.id));
        } else {
          bloc.add(const ActionEvent.startCancelled());
        }
      },
      builder: (context, state) => state.maybeWhen(
        orElse: () => const Center(child: CircularProgressIndicator()),
        error: (failure) => Center(child: Text(failure.localizedMessage(l10n))),
        loaded: (running, grid, currentGroupId, _, _, todayTotals) => Column(
          children: [
            Expanded(
              child: running.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noRunningActions,
                        style: textTheme.bodyMedium,
                      ),
                    )
                  : RunningActionsList(running: running, todayTotals: todayTotals),
            ),
            const Divider(height: 1),
            BlocBuilder<AppSettingsCubit, AppSettingsState>(
              buildWhen: (p, c) =>
                  p.settings.columnCount != c.settings.columnCount ||
                  p.settings.rowCount != c.settings.rowCount,
              builder: (context, state) => ActionGrid(
                actions: grid,
                columns: state.settings.columnCount,
                rowCount: state.settings.rowCount,
                currentGroupId: currentGroupId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
