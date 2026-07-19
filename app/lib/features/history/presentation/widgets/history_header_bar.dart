import 'package:flutter/material.dart';

import 'package:timefocus/features/history/domain/entities/history_header_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/ticking_timer.dart';

/// History screen header (FR-039), one row per metric: work time (excl.
/// Sleep) vs. the total of what's currently listed, Pomodoro
/// completed/interrupted, water drunk/goal.
class HistoryHeaderBar extends StatelessWidget {
  const HistoryHeaderBar({required this.header, required this.listTotalSec, super.key});

  final HistoryHeaderEntity header;

  /// Sum of the durations of whatever HistoryPage's list is currently
  /// showing (intervals or totals) — not FR-039's Sleep-excluding figure.
  final int listTotalSec;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _HeaderRow(
            icon: Icons.timer_outlined,
            values: [
              (label: l10n.historyListTotal, value: formatDuration(listTotalSec)),
              (label: l10n.systemActionWork, value: formatDuration(header.workSec)),
            ],
          ),
          _HeaderRow(
            icon: Icons.local_fire_department_outlined,
            values: [
              (label: null, value: l10n.historyPomodoroCompleted(header.pomodoroCompleted)),
              (label: null, value: l10n.historyPomodoroInterrupted(header.pomodoroInterrupted)),
            ],
          ),
          _HeaderRow(
            icon: Icons.water_drop_outlined,
            values: [
              (label: l10n.waterConsumed, value: l10n.waterGoalMl(header.waterDrankMl)),
              (label: l10n.waterGoal, value: l10n.waterGoalMl(header.waterGoalMl)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.icon, required this.values});

  final IconData icon;
  final List<({String? label, String value})> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = values
        .map((v) => v.label == null ? v.value : '${v.label}: ${v.value}')
        .join('  ·  ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: text,
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 12,
                children: [
                  for (final v in values)
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          if (v.label != null)
                            TextSpan(
                              text: '${v.label}: ',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          TextSpan(
                            text: v.value,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
