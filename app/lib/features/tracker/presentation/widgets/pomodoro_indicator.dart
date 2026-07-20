import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/core/utils/time_guard.dart';
import 'package:timefocus/features/pomodoro/presentation/bloc/pomodoro_bloc.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/ticking_timer.dart';

/// Shown on a running card when this activity currently drives the Pomodoro
/// (work or break): type/cycle ("2/4"), live countdown, skip button.
class PomodoroIndicator extends StatelessWidget {
  const PomodoroIndicator({required this.actionNameId, super.key});

  final int actionNameId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      builder: (context, state) {
        final view = switch (state) {
          PomodoroWorkRunning(:final session, :final endsAt, :final cyclesBeforeLongBreak)
              when session.actionNameId == actionNameId =>
            (endsAt: endsAt, cycle: session.cycleNumber, total: cyclesBeforeLongBreak),
          PomodoroBreakRunning(:final session, :final endsAt, :final parentActionId)
              when parentActionId == actionNameId =>
            (endsAt: endsAt, cycle: session.cycleNumber, total: session.cycleNumber),
          _ => null,
        };
        if (view == null) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.cycleNumber(view.cycle, view.total),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 8),
            _Countdown(endsAt: view.endsAt, style: theme.textTheme.bodySmall),
            IconButton(
              tooltip: l10n.skipPomodoro,
              iconSize: 20,
              onPressed: () => context.read<PomodoroBloc>().add(const PomodoroEvent.skipped()),
              icon: const Icon(Icons.skip_next),
            ),
          ],
        );
      },
    );
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.endsAt, this.style});

  final DateTime endsAt;
  final TextStyle? style;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.endsAt.delayFrom(DateTime.now()).inSeconds;
    return Text(formatDuration(remaining), style: widget.style);
  }
}
