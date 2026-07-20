import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/schedule/domain/entities/timeline_item.dart';
import 'package:timefocus/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:timefocus/features/schedule/presentation/widgets/edit_event_sheet.dart';
import 'package:timefocus/features/schedule/presentation/widgets/timeline_view.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// US4: vertical day timeline (plan + fact + water + reminders, FR-030).
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduleCubit>(
      create: (_) {
        final cubit = getIt<ScheduleCubit>();
        unawaited(cubit.subscribe());
        return cubit;
      },
      child: const _SchedulePageContent(),
    );
  }
}

class _SchedulePageContent extends StatelessWidget {
  const _SchedulePageContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleTitle)),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) => switch (state) {
          ScheduleInitial() => const Center(child: CircularProgressIndicator()),
          ScheduleError(:final failure) => Center(child: Text(failure.localizedMessage(l10n))),
          ScheduleLoaded(:final timeline) =>
            timeline.isEmpty
                ? Center(child: Text(l10n.scheduleNoEvents))
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: TimelineView(
                      items: timeline,
                      onTap: (item) => _onItemTap(context, item),
                    ),
                  ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.scheduleAddEvent,
        onPressed: () => unawaited(showEditEventSheet(context)),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onItemTap(BuildContext context, TimelineItem item) {
    if (item.kind == TimelineItemKind.planned && item.event != null) {
      unawaited(
        showEditEventSheet(
          context,
          existing: item.event,
          initialTimeMinutes: item.event!.timeMinutes,
        ),
      );
    }
  }
}
