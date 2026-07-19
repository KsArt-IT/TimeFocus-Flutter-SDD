import 'dart:async';
import 'dart:ui' show Locale;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_session_entity.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_settings_entity.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_repository.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_settings_repository.dart';
import 'package:timefocus/features/pomodoro/domain/usecases/finish_pomodoro_interval_usecase.dart';
import 'package:timefocus/features/pomodoro/presentation/bloc/pomodoro_event.dart';
import 'package:timefocus/features/pomodoro/presentation/bloc/pomodoro_state.dart';
import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/features/schedule/domain/usecases/check_strict_events_usecase.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/notification_type.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';
import 'package:timefocus/shared/widgets/schedule_event_localization.dart';
import 'package:vibration/vibration.dart';

export 'package:timefocus/features/pomodoro/presentation/bloc/pomodoro_event.dart';
export 'package:timefocus/features/pomodoro/presentation/bloc/pomodoro_state.dart';

/// Global Pomodoro bloc: work/break cycle, coordinated with ActionBloc only
/// through RootBlocListener (contracts/blocs.md).
@lazySingleton
class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroState> {
  PomodoroBloc(
    this._sessions,
    this._settings,
    this._actions,
    this._finishInterval,
    this._scheduler,
    this._strictEvents,
  ) : super(const PomodoroState.idle()) {
    on<PomodoroStarted>(_onStarted, transformer: droppable());
    on<PomodoroWorkIntervalFinished>(_onWorkFinished, transformer: sequential());
    on<PomodoroBreakActivityStarted>(_onBreakActivityStarted, transformer: sequential());
    on<PomodoroInterrupted>(_onInterrupted, transformer: sequential());
    on<PomodoroSkipped>(_onSkipped, transformer: droppable());
    on<PomodoroBreakFinished>(_onBreakFinished, transformer: sequential());
    on<PomodoroBreakExtended>(_onBreakExtended, transformer: droppable());
  }

  final PomodoroRepository _sessions;
  final PomodoroSettingsRepository _settings;
  final ActionNameRepository _actions;
  final FinishPomodoroIntervalUseCase _finishInterval;
  final NotificationScheduler _scheduler;
  final CheckStrictEventsUseCase _strictEvents;

  /// stoppedByUser is the only interrupt reason that resets the cycle
  /// (FR-014); the DB has no column for "why interrupted", so the reset is
  /// tracked in memory until the action's cycle naturally restarts at 1.
  final Set<int> _cycleResetActions = {};

  /// Cycle to resume at when no new session was created yet (idle /
  /// suggestBreak outcomes) — consumed by the next manual start.
  final Map<int, int> _pendingNextCycle = {};

  Timer? _intervalTimer;

  /// Forces the running work interval to stop at the soonest strict
  /// schedule event it won't reach (FR-031/032) — armed alongside
  /// [_intervalTimer], since there is no background process to do this.
  Timer? _strictEventTimer;

  Future<void> _onStarted(PomodoroStarted event, Emitter<PomodoroState> emit) async {
    final cycle = await _resolveStartCycle(event.actionNameId);
    final settingsResult = await _settings.current();
    if (isClosed) return;
    final settings = settingsResult.valueOrNull;
    if (settings == null) {
      _emitError(settingsResult, emit);
      return;
    }

    final result = await _sessions.startSession(
      actionNameId: event.actionNameId,
      historyId: event.historyId,
      type: event.type,
      cycleNumber: cycle,
      isBreak: false,
    );
    if (isClosed) return;
    final session = result.valueOrNull;
    if (session == null) {
      _emitError(result, emit);
      return;
    }

    final endsAt = session.startTime.add(Duration(seconds: session.plannedTime));
    emit(
      PomodoroState.workRunning(
        session: session,
        endsAt: endsAt,
        cyclesBeforeLongBreak: settings.cyclesBeforeLongBreak,
      ),
    );
    _armTimer(endsAt, () => add(PomodoroEvent.workIntervalFinished(session.id)));
    await _scheduleWorkFinished(session, event.actionNameId, settings);
    await _checkStrictEvents(session.startTime, endsAt);
  }

  /// FR-032: warn immediately if this work interval won't finish before a
  /// strict event, and force-interrupt at that event's exact time (FR-031)
  /// since completion only happens via [PomodoroWorkIntervalFinished].
  Future<void> _checkStrictEvents(DateTime now, DateTime workEndAt) async {
    _strictEventTimer?.cancel();
    final result = await _strictEvents(now: now, workEndAt: workEndAt);
    if (isClosed) return;
    final missed = result.valueOrNull;
    if (missed == null || missed.isEmpty) return;

    final soonest = missed.first;
    final day = DateTime(now.year, now.month, now.day);
    final eventAt = day.add(Duration(minutes: soonest.timeMinutes));
    final delay = eventAt.difference(DateTime.now());
    _strictEventTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!isClosed) add(const PomodoroEvent.interrupted(PomodoroStopReason.strictEvent));
    });

    await _scheduleMealStrictWarning(soonest, eventAt, workEndAt);
  }

  Future<void> _scheduleMealStrictWarning(
    ScheduleEventEntity event,
    DateTime eventAt,
    DateTime workEndAt,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final minutesUntilEvent = eventAt.difference(DateTime.now()).inMinutes;
    final eventName = event.displayName(l10n);
    await _scheduler.schedule(
      NotificationDraft(
        type: NotificationType.mealStrictWarning,
        scheduledAt: DateTime.now(),
        title: l10n.mealStrictWarningTitle(eventName),
        body: l10n.mealStrictWarningBody(eventName, minutesUntilEvent),
        payload: {
          'scheduleEventId': event.id,
          'minutesUntilEvent': minutesUntilEvent,
          'currentPomodoroEndAt': workEndAt.toIso8601String(),
        },
      ),
    );
  }

  Future<int> _resolveStartCycle(int actionNameId) async {
    if (_cycleResetActions.remove(actionNameId)) return 1;
    final pending = _pendingNextCycle.remove(actionNameId);
    if (pending != null) return pending;
    final last = await _sessions.lastSessionForAction(actionNameId);
    return last.valueOrNull?.cycleNumber ?? 1;
  }

  Future<void> _onWorkFinished(
    PomodoroWorkIntervalFinished event,
    Emitter<PomodoroState> emit,
  ) async {
    final current = state;
    if (current is! PomodoroWorkRunning || current.session.id != event.sessionId) return;
    _intervalTimer?.cancel();
    _strictEventTimer?.cancel();
    await _scheduler.cancelByType(NotificationType.pomodoroFinished);
    if (isClosed) return;

    final actionId = current.session.actionNameId!;
    final actionResult = await _actions.getById(actionId);
    if (isClosed) return;
    final action = actionResult.valueOrNull;
    if (action == null) {
      _emitError(actionResult, emit);
      return;
    }

    final outcomeResult = await _finishInterval(workSession: current.session, workAction: action);
    if (isClosed) return;
    final outcome = outcomeResult.valueOrNull;
    if (outcome == null) {
      _emitError(outcomeResult, emit);
      return;
    }

    await _playCompletionFeedback();
    if (isClosed) return;

    switch (outcome) {
      case FinishIdle(:final nextCycle):
        _pendingNextCycle[actionId] = nextCycle;
        emit(const PomodoroState.idle());

      case FinishBreakSuggested(:final breakActionId, :final nextCycle, :final isLong):
        _pendingNextCycle[actionId] = nextCycle;
        emit(
          PomodoroState.idle(
            suggestion: BreakSuggestion(
              breakActionId: breakActionId,
              nextCycle: nextCycle,
              isLong: isLong,
            ),
          ),
        );

      case FinishStartBreak(:final breakActionId, :final nextCycle, :final isLong):
        // Ask ActionBloc (via RootBlocListener) to actually start the break
        // activity; the session row is created once it confirms
        // (PomodoroBreakActivityStarted), so it gets the real historyId.
        emit(
          PomodoroState.breakShouldStart(
            breakActionId: breakActionId,
            parentActionId: actionId,
            nextCycle: nextCycle,
            isLong: isLong,
          ),
        );

      case FinishWorkRestarted(session: final next):
        final settingsResult = await _settings.current();
        if (isClosed) return;
        final settings = settingsResult.valueOrNull;
        final endsAt = next.startTime.add(Duration(seconds: next.plannedTime));
        emit(
          PomodoroState.workRunning(
            session: next,
            endsAt: endsAt,
            cyclesBeforeLongBreak: settings?.cyclesBeforeLongBreak ?? next.cycleNumber,
          ),
        );
        _armTimer(endsAt, () => add(PomodoroEvent.workIntervalFinished(next.id)));
        if (settings != null) await _scheduleWorkFinished(next, actionId, settings);
    }
  }

  Future<void> _onBreakActivityStarted(
    PomodoroBreakActivityStarted event,
    Emitter<PomodoroState> emit,
  ) async {
    final current = state;
    if (current is! PomodoroBreakShouldStart) return;

    final result = await _sessions.startSession(
      actionNameId: current.breakActionId,
      historyId: event.historyId,
      type: current.isLong ? PomodoroType.long : PomodoroType.short,
      cycleNumber: current.nextCycle,
      isBreak: true,
    );
    if (isClosed) return;
    final session = result.valueOrNull;
    if (session == null) {
      _emitError(result, emit);
      return;
    }

    final endsAt = session.startTime.add(Duration(seconds: session.plannedTime));
    emit(
      PomodoroState.breakRunning(
        session: session,
        endsAt: endsAt,
        parentActionId: current.parentActionId,
      ),
    );
    _armTimer(endsAt, () => add(PomodoroEvent.breakFinished(session.id)));
    await _scheduleBreakFinished(session, current.parentActionId, current.nextCycle);
  }

  Future<void> _onInterrupted(PomodoroInterrupted event, Emitter<PomodoroState> emit) async {
    final current = state;
    final activeId = switch (current) {
      PomodoroWorkRunning(:final session) => session.id,
      PomodoroBreakRunning(:final session) => session.id,
      _ => null,
    };
    if (activeId == null) return;

    _intervalTimer?.cancel();
    _strictEventTimer?.cancel();
    await _sessions.finish(activeId, PomodoroStatus.interrupted, DateTime.now());
    await _scheduler.cancelByType(NotificationType.pomodoroFinished);
    await _scheduler.cancelByType(NotificationType.breakFinished);
    if (isClosed) return;

    if (event.reason == PomodoroStopReason.stoppedByUser) {
      final actionId = switch (current) {
        PomodoroWorkRunning(:final session) => session.actionNameId,
        PomodoroBreakRunning(:final parentActionId) => parentActionId,
        _ => null,
      };
      if (actionId != null) _cycleResetActions.add(actionId);
    }
    emit(const PomodoroState.idle());
  }

  Future<void> _onSkipped(PomodoroSkipped event, Emitter<PomodoroState> emit) async {
    final current = state;
    final activeId = switch (current) {
      PomodoroWorkRunning(:final session) => session.id,
      PomodoroBreakRunning(:final session) => session.id,
      _ => null,
    };
    if (activeId == null) return;
    _intervalTimer?.cancel();
    _strictEventTimer?.cancel();
    await _sessions.finish(activeId, PomodoroStatus.skipped, DateTime.now());
    await _scheduler.cancelByType(NotificationType.pomodoroFinished);
    await _scheduler.cancelByType(NotificationType.breakFinished);
    if (isClosed) return;

    if (current is PomodoroBreakRunning) {
      emit(
        PomodoroState.readyToResumeWork(
          parentActionId: current.parentActionId,
          nextCycle: current.session.cycleNumber,
        ),
      );
    } else {
      emit(const PomodoroState.idle());
    }
  }

  Future<void> _onBreakFinished(PomodoroBreakFinished event, Emitter<PomodoroState> emit) async {
    final current = state;
    if (current is! PomodoroBreakRunning || current.session.id != event.sessionId) return;
    _intervalTimer?.cancel();
    await _sessions.finish(event.sessionId, PomodoroStatus.completed, DateTime.now());
    await _scheduler.cancelByType(NotificationType.breakFinished);
    if (isClosed) return;
    emit(
      PomodoroState.readyToResumeWork(
        parentActionId: current.parentActionId,
        nextCycle: current.session.cycleNumber,
      ),
    );
  }

  Future<void> _onBreakExtended(PomodoroBreakExtended event, Emitter<PomodoroState> emit) async {
    final current = state;
    if (current is! PomodoroBreakRunning) return;
    final newEndsAt = current.endsAt.add(Duration(minutes: event.minutes));
    _armTimer(newEndsAt, () => add(PomodoroEvent.breakFinished(current.session.id)));
    emit(
      PomodoroState.breakRunning(
        session: current.session,
        endsAt: newEndsAt,
        parentActionId: current.parentActionId,
      ),
    );
  }

  void _armTimer(DateTime endsAt, void Function() onFire) {
    _intervalTimer?.cancel();
    final delay = endsAt.difference(DateTime.now());
    _intervalTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!isClosed) onFire();
    });
  }

  Future<void> _scheduleWorkFinished(
    PomodoroSessionEntity session,
    int actionNameId,
    PomodoroSettingsEntity settings,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final actionResult = await _actions.getById(actionNameId);
    final breakActionId = actionResult.valueOrNull?.breakActionId;
    final isLongBreak = session.cycleNumber >= settings.cyclesBeforeLongBreak;
    final breakMin = settings.breakTimeFor(isLong: isLongBreak) ~/ 60;
    final endsAt = session.startTime.add(Duration(seconds: session.plannedTime));
    await _scheduler.schedule(
      NotificationDraft(
        type: NotificationType.pomodoroFinished,
        scheduledAt: endsAt,
        title: l10n.pomodoroFinishedTitle,
        body: l10n.pomodoroFinishedBody(breakMin),
        payload: {'actionId': actionNameId, 'breakActionId': breakActionId},
      ),
    );
  }

  Future<void> _scheduleBreakFinished(
    PomodoroSessionEntity session,
    int parentActionId,
    int pomodoroCount,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final actionResult = await _actions.getById(parentActionId);
    final name = actionResult.valueOrNull?.name ?? '';
    final endsAt = session.startTime.add(Duration(seconds: session.plannedTime));
    await _scheduler.schedule(
      NotificationDraft(
        type: NotificationType.breakFinished,
        scheduledAt: endsAt,
        title: l10n.breakFinishedTitle,
        body: l10n.breakFinishedBody(name),
        payload: {'parentActionId': parentActionId, 'pomodoroCount': pomodoroCount},
      ),
    );
  }

  Future<void> _playCompletionFeedback() async {
    final settingsResult = await _settings.current();
    final settings = settingsResult.valueOrNull;
    if (settings == null || !settings.vibrationEnabled) return;
    try {
      if (await Vibration.hasVibrator()) {
        unawaited(Vibration.vibrate(duration: 300));
      }
    } catch (e) {
      logger.w('vibration unavailable', error: e);
    }
  }

  void _emitError<T>(Result<T> result, Emitter<PomodoroState> emit) {
    final error = result.errorOrNull ?? const UnknownFailure('pomodoro error');
    logger.e('pomodoro transition failed', error: error);
    emit(PomodoroState.error(error));
  }

  @override
  Future<void> close() {
    _intervalTimer?.cancel();
    _strictEventTimer?.cancel();
    return super.close();
  }
}
