import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timefocus/features/pomodoro/presentation/bloc/pomodoro_bloc.dart';
import 'package:timefocus/features/tracker/domain/entities/transition_effect.dart'
    as tracker_effect;
import 'package:timefocus/features/tracker/domain/usecases/start_action_usecase.dart'
    show ActionStartSource;
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:toastification/toastification.dart';

/// Single coordination point between global Blocs (contracts/blocs.md).
/// Blocs never import each other; every cross-feature effect is wired here.
class RootBlocListener extends StatelessWidget {
  const RootBlocListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ActionBloc, ActionState>(
          listenWhen: (previous, current) => current.maybeMap(
            loaded: (s) => s.lastTransition != null,
            orElse: () => false,
          ),
          listener: _onActionTransition,
        ),
        BlocListener<PomodoroBloc, PomodoroState>(
          listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
          listener: _onPomodoroStateEntered,
        ),
      ],
      child: child,
    );
  }

  void _onActionTransition(BuildContext context, ActionState state) {
    final loaded = state as ActionLoaded;
    final effect = loaded.lastTransition;
    if (effect == null) return;

    switch (effect) {
      case tracker_effect.PomodoroShouldStart(
        :final actionNameId,
        :final historyId,
        :final pomodoroType,
      ):
        context.read<PomodoroBloc>().add(
          PomodoroEvent.started(
            actionNameId: actionNameId,
            historyId: historyId,
            type: pomodoroType,
          ),
        );

      case tracker_effect.PomodoroShouldStop(:final reason):
        context.read<PomodoroBloc>().add(PomodoroEvent.interrupted(_mapStopReason(reason)));

      case tracker_effect.PomodoroInterrupted(:final byAction, :final interruptedAction):
        final l10n = AppLocalizations.of(context);
        toastification.show(
          context: context,
          type: ToastificationType.warning,
          title: Text(l10n.pomodoroInterrupted),
          description: Text('${interruptedAction.name} → ${byAction.name}'),
          autoCloseDuration: const Duration(seconds: 4),
        );

      case tracker_effect.BreakStarted(:final historyId):
        // HudCubit.onPomodoroBreakStarted() wired in US3 (T043).
        context.read<PomodoroBloc>().add(PomodoroEvent.breakActivityStarted(historyId));
    }

    context.read<ActionBloc>().add(const ActionEvent.transitionHandled());
  }

  PomodoroStopReason _mapStopReason(tracker_effect.PomodoroStopReason reason) => switch (reason) {
    tracker_effect.PomodoroStopReason.pausedByUser => PomodoroStopReason.pausedByUser,
    tracker_effect.PomodoroStopReason.stoppedByUser => PomodoroStopReason.stoppedByUser,
    tracker_effect.PomodoroStopReason.pausedByOthers => PomodoroStopReason.pausedByOthers,
    tracker_effect.PomodoroStopReason.manualBreak => PomodoroStopReason.manualBreak,
    tracker_effect.PomodoroStopReason.secondPomodoro => PomodoroStopReason.secondPomodoro,
    // Strict schedule events are wired in US4 (T052); treat as a generic
    // system interruption meanwhile.
    tracker_effect.PomodoroStopReason.strictEvent => PomodoroStopReason.pausedByOthers,
  };

  void _onPomodoroStateEntered(BuildContext context, PomodoroState state) {
    switch (state) {
      case PomodoroReadyToResumeWork(:final parentActionId):
        context.read<ActionBloc>().add(
          ActionEvent.started(parentActionId, source: ActionStartSource.system),
        );
      case PomodoroBreakShouldStart(:final breakActionId):
        context.read<ActionBloc>().add(
          ActionEvent.started(breakActionId, source: ActionStartSource.system),
        );
      case PomodoroWorkRunning():
      case PomodoroIdle():
      case PomodoroBreakRunning():
      case PomodoroError():
        // HudCubit.onPomodoroStateChanged / NotificationBloc.ScheduleRecalculated
        // wired in US3 (T043) / US5 (T060).
        break;
    }
  }
}
