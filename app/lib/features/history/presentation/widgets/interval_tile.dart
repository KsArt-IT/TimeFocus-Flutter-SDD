import 'package:flutter/material.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/circle_fa_icon.dart';
import 'package:timefocus/shared/widgets/ticking_timer.dart';

/// One row of the "Intervals" mode list — tap opens the session editor.
class IntervalTile extends StatelessWidget {
  const IntervalTile({required this.interval, required this.onTap, super.key});

  final HistoryIntervalEntity interval;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = Color(interval.color);
    final name = localizedActionName(
      l10n,
      name: interval.actionName,
      isSystem: interval.isSystemAction,
    );
    final durationSec = interval.finishedAt.difference(interval.startedAt).inSeconds;

    return ListTile(
      onTap: onTap,
      leading: CircleFaIcon(
        icon: interval.icon,
        color: color,
      ),
      title: Text(name),
      subtitle: Text(_timeRange(interval.startedAt, interval.finishedAt)),
      trailing: Text(
        formatDuration(durationSec < 0 ? 0 : durationSec),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  String _timeRange(DateTime start, DateTime end) => '${_hm(start)} – ${_hm(end)}';

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
