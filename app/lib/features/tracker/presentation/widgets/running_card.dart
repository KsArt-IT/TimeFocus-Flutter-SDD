import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';
import 'package:timefocus/shared/widgets/ticking_timer.dart';

/// Card of a running activity: icon, name, ticking timer (frozen on pause —
/// FR-006), total for today, pause/resume/stop controls.
class RunningCard extends StatelessWidget {
  const RunningCard({required this.running, required this.todayTotalSec, super.key});

  final RunningWithNameEntity running;
  final int todayTotalSec;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = Color(running.action.color);
    final name = running.action.localizedName(l10n);
    final isActive = running.isActive;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: FaIcon(
                faIconFromCode(running.action.icon),
                color: color,
                size: 18,
                semanticLabel: name,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      TickingTimer(
                        startedAt: running.startedAt,
                        accumulatedSec: running.accumulatedSec,
                        isActive: isActive,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatDuration(todayTotalSec),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isActive)
              IconButton(
                tooltip: l10n.pauseAction,
                iconSize: 28,
                onPressed: () =>
                    context.read<ActionBloc>().add(ActionEvent.paused(running.runningId)),
                icon: const Icon(Icons.pause_circle_outline),
              )
            else
              IconButton(
                tooltip: l10n.resumeAction,
                iconSize: 28,
                onPressed: () =>
                    context.read<ActionBloc>().add(ActionEvent.resumed(running.action.id)),
                icon: const Icon(Icons.play_circle_outline),
              ),
            IconButton(
              tooltip: l10n.stopAction,
              iconSize: 28,
              onPressed: () =>
                  context.read<ActionBloc>().add(ActionEvent.stopped(running.runningId)),
              icon: const Icon(Icons.stop_circle_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
