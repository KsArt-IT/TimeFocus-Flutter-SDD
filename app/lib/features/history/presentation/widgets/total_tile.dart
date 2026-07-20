import 'package:flutter/material.dart';
import 'package:timefocus/features/history/domain/entities/history_total_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/circle_fa_icon.dart';
import 'package:timefocus/shared/widgets/ticking_timer.dart';

/// One row of the "Summary" mode list — total time per activity.
class TotalTile extends StatelessWidget {
  const TotalTile({required this.total, super.key});

  final HistoryTotalEntity total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = Color(total.color);
    final name = localizedActionName(l10n, name: total.actionName, isSystem: total.isSystemAction);

    return ListTile(
      leading: CircleFaIcon(
        icon: total.icon,
        color: color,
      ),
      title: Text(name),
      subtitle: Text(l10n.historySessionsCount(total.sessions)),
      trailing: Text(
        formatDuration(total.totalSec),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}
