import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/router/app_router.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_intent.dart';
import 'package:timefocus/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:timefocus/features/pomodoro/presentation/bloc/pomodoro_bloc.dart';
import 'package:timefocus/features/tracker/domain/entities/transition_effect.dart'
    as tracker_effect;
import 'package:timefocus/features/tracker/domain/usecases/start_action_usecase.dart'
    show ActionStartSource;
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/action_status.dart';
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
        BlocListener<ActionBloc, ActionState>(
          listenWhen: (previous, current) => _isMuted(previous) && !_isMuted(current),
          listener: (context, state) => context.read<NotificationBloc>().add(
            const NotificationEvent.scheduleRecalculated(ScheduleRecalcTrigger.muteEnded),
          ),
        ),
        BlocListener<PomodoroBloc, PomodoroState>(
          listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
          listener: _onPomodoroStateEntered,
        ),
        BlocListener<HudCubit, HudState>(
          listenWhen: (previous, current) => current is HudError,
          listener: _onHudError,
        ),
        BlocListener<NotificationBloc, NotificationState>(
          listenWhen: (previous, current) => current.pendingIntent != null,
          listener: _onNotificationIntent,
        ),
      ],
      child: child,
    );
  }

  static bool _isMuted(ActionState state) => state.maybeMap(
    loaded: (s) => s.running.any(
      (r) => r.status == ActionStatus.active && SystemActionKeys.muting.contains(r.action.name),
    ),
    orElse: () => false,
  );

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
    tracker_effect.PomodoroStopReason.strictEvent => PomodoroStopReason.strictEvent,
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
        context.read<HudCubit>().onPomodoroStateChanged(isActive: true);
      case PomodoroIdle():
        context.read<HudCubit>().onPomodoroStateChanged(isActive: false);
        context.read<NotificationBloc>().add(
          const NotificationEvent.scheduleRecalculated(ScheduleRecalcTrigger.pomodoroEnded),
        );
      case PomodoroBreakRunning():
        context.read<HudCubit>().onPomodoroBreakStarted();
      case PomodoroError(:final failure):
        _showFailureToast(context, failure);
    }
  }

  void _onHudError(BuildContext context, HudState state) {
    if (state is! HudError) return;
    _showFailureToast(context, state.failure);
  }

  void _showFailureToast(BuildContext context, AppFailure failure) {
    final l10n = AppLocalizations.of(context);
    toastification.show(
      context: context,
      type: ToastificationType.error,
      title: Text(failure.localizedMessage(l10n)),
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  void _onNotificationIntent(BuildContext context, NotificationState state) {
    final intent = state.pendingIntent;
    if (intent == null) return;

    switch (intent) {
      case OpenTrackerIntent():
        break;
      case ResumeWorkIntent(:final actionNameId):
        context.read<ActionBloc>().add(
          ActionEvent.started(actionNameId, source: ActionStartSource.system),
        );
      case StartActionIntent(:final actionNameId):
        context.read<ActionBloc>().add(ActionEvent.started(actionNameId));
      case ExtendBreakIntent(:final minutes):
        context.read<PomodoroBloc>().add(PomodoroEvent.breakExtended(minutes));
    }

    rootNavigatorKey.currentContext?.go(AppRoutes.tracker);
    context.read<NotificationBloc>().add(const NotificationEvent.intentHandled());
  }
}
