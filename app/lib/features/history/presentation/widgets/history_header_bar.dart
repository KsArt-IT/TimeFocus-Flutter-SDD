import 'package:flutter/material.dart';

import 'package:timefocus/features/history/domain/entities/history_header_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/ticking_timer.dart';

/// History screen header (FR-039): total tracked time (excl. Sleep),
/// Pomodoro completed/interrupted, water drunk/goal.
class HistoryHeaderBar extends StatelessWidget {
  const HistoryHeaderBar({required this.header, super.key});

  final HistoryHeaderEntity header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.timer_outlined,
              primary: formatDuration(header.totalSec),
              secondary: l10n.historyWorkTotal,
            ),
          ),
          Expanded(
            child: _Stat(
              icon: Icons.local_fire_department_outlined,
              primary:
                  '${header.pomodoroCompleted}/${header.pomodoroCompleted + header.pomodoroInterrupted}',
              secondary: l10n.settingsPomodoro,
            ),
          ),
          Expanded(
            child: _Stat(
              icon: Icons.water_drop_outlined,
              primary:
                  '${l10n.waterGoalMl(header.waterDrankMl)}/${l10n.waterGoalMl(header.waterGoalMl)}',
              secondary: l10n.waterGoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.primary, required this.secondary});

  final IconData icon;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$secondary: $primary',
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            primary,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            secondary,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
