import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/core/router/app_router.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/features/tracker/presentation/widgets/pomodoro_indicator.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/circle_fa_icon.dart';
import 'package:timefocus/shared/widgets/ticking_timer.dart';

/// Card of a running activity: icon, name, ticking timer (frozen on pause —
/// FR-006), total for today, pause/resume/stop controls.
class RunningCard extends StatelessWidget {
  const RunningCard({
    required this.running,
    required this.todayTotalSec,
    super.key,
  });

  final RunningWithNameEntity running;
  final int todayTotalSec;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = Color(running.action.color);
    final name = running.action.localizedName(l10n);
    final isActive = running.isActive;

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.sessionEdit}/${running.historyId}'),
      behavior: .opaque,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.radius3x,
            AppDimens.radius2x,
            AppDimens.radius1x,
            AppDimens.radius2x,
          ),
          child: Row(
            children: [
              CircleFaIcon(
                name: name,
                icon: running.action.icon,
                color: color,
              ),
              const SizedBox(width: AppDimens.radius3x),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium,
                      overflow: .ellipsis,
                    ),
                    TickingTimer(
                      startedAt: running.startedAt,
                      accumulatedSec: todayTotalSec, // running.accumulatedSec,
                      isActive: isActive,
                    ),
                    if (running.action.mode == ActionMode.pomodoro ||
                        running.action.mode == ActionMode.breakFor)
                      PomodoroIndicator(actionNameId: running.action.id),
                  ],
                ),
              ),
              if (isActive)
                IconButton(
                  tooltip: l10n.pauseAction,
                  iconSize: AppDimens.iconSizeMedium,
                  onPressed: () => context.read<ActionBloc>().add(.paused(running.runningId)),
                  icon: const Icon(Icons.pause_circle_outline),
                )
              else
                IconButton(
                  tooltip: l10n.resumeAction,
                  iconSize: AppDimens.iconSizeMedium,
                  onPressed: () => context.read<ActionBloc>().add(.resumed(running.action.id)),
                  icon: const Icon(Icons.play_circle_outline),
                ),
              IconButton(
                tooltip: l10n.stopAction,
                iconSize: AppDimens.iconSizeMedium,
                onPressed: () => context.read<ActionBloc>().add(.stopped(running.runningId)),
                icon: const Icon(Icons.stop_circle_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
