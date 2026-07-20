import 'package:flutter/material.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/features/tracker/presentation/widgets/running_card.dart';

/// Scrollable list of running activity cards (US1 top section).
class RunningActionsList extends StatelessWidget {
  const RunningActionsList({
    required this.running,
    required this.todayTotals,
    super.key,
  });

  final List<RunningWithNameEntity> running;
  final Map<int, int> todayTotals;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const .fromLTRB(
        AppDimens.inset2x,
        0,
        AppDimens.inset2x,
        AppDimens.bottomPaddingSmaller,
      ),
      itemCount: running.length,
      itemBuilder: (context, index) {
        final r = running[index];

        return RunningCard(
          key: ValueKey(r.runningId),
          running: r,
          todayTotalSec: todayTotals[r.action.id] ?? 0,
        );
      },
    );
  }
}
