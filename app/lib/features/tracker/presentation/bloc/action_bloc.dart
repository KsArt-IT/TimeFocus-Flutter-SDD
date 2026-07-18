import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/transition_effect.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_running_repository.dart';
import 'package:timefocus/features/tracker/domain/usecases/pause_action_usecase.dart';
import 'package:timefocus/features/tracker/domain/usecases/start_action_usecase.dart';
import 'package:timefocus/features/tracker/domain/usecases/stop_action_usecase.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_event.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_state.dart';

export 'package:timefocus/features/tracker/presentation/bloc/action_event.dart';
export 'package:timefocus/features/tracker/presentation/bloc/action_state.dart';

/// Global tracker bloc: start/pause/stop of activities, grid with in-place
/// groups. Coordination with Pomodoro only via TransitionEffect +
/// RootBlocListener.
@lazySingleton
class ActionBloc extends Bloc<ActionEvent, ActionState> {
  ActionBloc(
    this._runningRepository,
    this._actionRepository,
    this._startAction,
    this._pauseAction,
    this._stopAction,
  ) : super(const ActionState.initial()) {
    on<ActionsSubscribed>(_onSubscribed, transformer: restartable());
    on<ActionGroupOpened>(_onGroupOpened, transformer: restartable());
    on<ActionStarted>(_onStarted, transformer: droppable());
    on<ActionStartConfirmed>(_onStartConfirmed, transformer: droppable());
    on<ActionStartCancelled>(_onStartCancelled);
    on<ActionPaused>(_onPaused, transformer: droppable());
    on<ActionResumed>(_onResumed, transformer: droppable());
    on<ActionStopped>(_onStopped, transformer: droppable());
    on<ActionTransitionHandled>(_onTransitionHandled);
    on<ActionDataChanged>(_onDataChanged, transformer: sequential());
  }

  final ActionRunningRepository _runningRepository;
  final ActionNameRepository _actionRepository;
  final StartActionUseCase _startAction;
  final PauseActionUseCase _pauseAction;
  final StopActionUseCase _stopAction;

  StreamSubscription<List<RunningWithNameEntity>>? _runningSub;
  StreamSubscription<List<ActionNameEntity>>? _gridSub;

  List<RunningWithNameEntity> _running = const [];
  List<ActionNameEntity> _grid = const [];
  Map<int, int> _todayTotals = const {};
  int? _groupId;

  ActionLoaded get _loaded => switch (state) {
    final ActionLoaded loaded => loaded,
    _ => const ActionState.loaded() as ActionLoaded,
  };

  Future<void> _onSubscribed(ActionsSubscribed event, Emitter<ActionState> emit) async {
    emit(const ActionState.loading());
    await _subscribeGrid(_groupId);
    await _runningSub?.cancel();
    _runningSub = _runningRepository.watchRunning().listen(
      (running) async {
        _running = running;
        _todayTotals = await _computeTodayTotals(running);
        if (isClosed) return;
        add(const ActionEvent.dataChanged());
      },
      onError: (Object e) => logger.e('running stream error', error: e),
    );
  }

  Future<void> _onGroupOpened(ActionGroupOpened event, Emitter<ActionState> emit) async {
    _groupId = event.groupId;
    await _subscribeGrid(event.groupId);
  }

  Future<void> _subscribeGrid(int? groupId) async {
    await _gridSub?.cancel();
    _gridSub = _actionRepository.watchGrid(groupId: groupId).listen(
      (grid) {
        _grid = grid;
        if (isClosed) return;
        add(const ActionEvent.dataChanged());
      },
      onError: (Object e) => logger.e('grid stream error', error: e),
    );
  }

  void _onDataChanged(ActionDataChanged event, Emitter<ActionState> emit) {
    emit(
      _loaded.copyWith(
        running: _running,
        grid: _grid,
        currentGroupId: _groupId,
        todayTotals: _todayTotals,
      ),
    );
  }

  Future<Map<int, int>> _computeTodayTotals(List<RunningWithNameEntity> running) async {
    final now = DateTime.now();
    final totals = <int, int>{};
    for (final r in running) {
      final result = await _runningRepository.todayTotalSec(r.action.id, now);
      totals[r.action.id] = result.valueOrNull ?? 0;
    }
    return totals;
  }

  Future<void> _onStarted(ActionStarted event, Emitter<ActionState> emit) =>
      _start(event.actionNameId, source: event.source, confirmed: false, emit: emit);

  Future<void> _onStartConfirmed(ActionStartConfirmed event, Emitter<ActionState> emit) =>
      _start(event.actionNameId, source: ActionStartSource.user, confirmed: true, emit: emit);

  Future<void> _start(
    int actionNameId, {
    required ActionStartSource source,
    required bool confirmed,
    required Emitter<ActionState> emit,
  }) async {
    final result = await _startAction(actionNameId, source: source, confirmed: confirmed);
    if (isClosed) return;
    result.fold(
      success: (outcome) => switch (outcome) {
        StartNeedsConfirmation(:final action) => emit(
          _loaded.copyWith(pendingConfirmation: action),
        ),
        StartStarted(:final effects) => _emitEffects(effects, emit),
        StartNoop() => null,
      },
      failure: (e) => _emitFailure(e, emit),
    );
  }

  void _onStartCancelled(ActionStartCancelled event, Emitter<ActionState> emit) {
    emit(_loaded.copyWith(pendingConfirmation: null));
  }

  Future<void> _onPaused(ActionPaused event, Emitter<ActionState> emit) async {
    final result = await _pauseAction(event.runningId);
    if (isClosed) return;
    result.fold(
      success: (effects) => _emitEffects(effects, emit),
      failure: (e) => _emitFailure(e, emit),
    );
  }

  Future<void> _onResumed(ActionResumed event, Emitter<ActionState> emit) =>
      _start(event.actionNameId, source: ActionStartSource.user, confirmed: false, emit: emit);

  Future<void> _onStopped(ActionStopped event, Emitter<ActionState> emit) async {
    final result = await _stopAction(event.runningId);
    if (isClosed) return;
    result.fold(
      success: (effects) => _emitEffects(effects, emit),
      failure: (e) => _emitFailure(e, emit),
    );
  }

  void _onTransitionHandled(ActionTransitionHandled event, Emitter<ActionState> emit) {
    emit(_loaded.copyWith(lastTransition: null, pendingConfirmation: null));
  }

  void _emitEffects(List<TransitionEffect> effects, Emitter<ActionState> emit) {
    final base = _loaded.copyWith(pendingConfirmation: null);
    var current = base;
    if (effects.isEmpty) {
      emit(current);
      return;
    }
    for (final effect in effects) {
      current = current.copyWith(lastTransition: effect);
      emit(current);
    }
  }

  void _emitFailure(AppFailure e, Emitter<ActionState> emit) {
    logger.e('action transition failed', error: e);
    emit(ActionState.error(e));
    // Recover to data state so the UI keeps working.
    add(const ActionEvent.dataChanged());
  }

  @override
  Future<void> close() async {
    await _runningSub?.cancel();
    await _gridSub?.cancel();
    return super.close();
  }
}
