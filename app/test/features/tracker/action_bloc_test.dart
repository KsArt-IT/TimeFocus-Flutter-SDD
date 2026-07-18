import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/transition_effect.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_running_repository.dart';
import 'package:timefocus/features/tracker/domain/usecases/pause_action_usecase.dart';
import 'package:timefocus/features/tracker/domain/usecases/start_action_usecase.dart';
import 'package:timefocus/features/tracker/domain/usecases/stop_action_usecase.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/action_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

class _MockRunningRepo extends Mock implements ActionRunningRepository {}

class _MockActionRepo extends Mock implements ActionNameRepository {}

class _MockStart extends Mock implements StartActionUseCase {}

class _MockPause extends Mock implements PauseActionUseCase {}

class _MockStop extends Mock implements StopActionUseCase {}

const work = ActionNameEntity(
  id: 1,
  name: 'work',
  color: 0,
  icon: 0,
  mode: ActionMode.pomodoro,
  pomodoroType: PomodoroType.normal,
);

const rest = ActionNameEntity(id: 4, name: 'rest', color: 0, icon: 0);

void main() {
  setUpAll(() {
    registerFallbackValue(ActionStartSource.user);
  });

  late _MockRunningRepo runningRepo;
  late _MockActionRepo actionRepo;
  late _MockStart start;
  late _MockPause pause;
  late _MockStop stop;

  setUp(() {
    runningRepo = _MockRunningRepo();
    actionRepo = _MockActionRepo();
    start = _MockStart();
    pause = _MockPause();
    stop = _MockStop();

    when(() => runningRepo.watchRunning()).thenAnswer((_) => const Stream.empty());
    when(
      () => actionRepo.watchGrid(groupId: any(named: 'groupId')),
    ).thenAnswer((_) => Stream.value(const [work, rest]));
    when(
      () => runningRepo.todayTotalSec(any(), any()),
    ).thenAnswer((_) async => const Result.success(0));
  });

  ActionBloc build() => ActionBloc(runningRepo, actionRepo, start, pause, stop);

  blocTest<ActionBloc, ActionState>(
    'subscribed → loading, then loaded with grid',
    build: build,
    act: (bloc) => bloc.add(const ActionEvent.subscribed()),
    expect: () => [
      const ActionState.loading(),
      const ActionState.loaded(grid: [work, rest]),
    ],
  );

  blocTest<ActionBloc, ActionState>(
    'running stream data is sorted into loaded state',
    build: build,
    setUp: () {
      final running = RunningWithNameEntity(
        runningId: 10,
        historyId: 100,
        action: work,
        status: ActionStatus.active,
        startedAt: DateTime(2026, 7, 18, 9),
      );
      when(() => runningRepo.watchRunning()).thenAnswer((_) => Stream.value([running]));
      when(
        () => runningRepo.todayTotalSec(work.id, any()),
      ).thenAnswer((_) async => const Result.success(300));
    },
    act: (bloc) => bloc.add(const ActionEvent.subscribed()),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      final state = bloc.state as ActionLoaded;
      expect(state.running.single.runningId, 10);
      expect(state.todayTotals[work.id], 300);
    },
  );

  blocTest<ActionBloc, ActionState>(
    'start needing confirmation → pendingConfirmation set',
    build: build,
    setUp: () {
      when(
        () => start(
          work.id,
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => const Result.success(StartActionOutcome.needsConfirmation(work)));
    },
    act: (bloc) => bloc.add(const ActionEvent.started(1)),
    expect: () => [const ActionState.loaded(pendingConfirmation: work)],
  );

  blocTest<ActionBloc, ActionState>(
    'cancelled confirmation clears pendingConfirmation',
    build: build,
    seed: () => const ActionState.loaded(pendingConfirmation: work),
    act: (bloc) => bloc.add(const ActionEvent.startCancelled()),
    expect: () => [const ActionState.loaded()],
  );

  blocTest<ActionBloc, ActionState>(
    'confirmed start emits effects one by one',
    build: build,
    setUp: () {
      when(
        () => start(work.id, confirmed: true),
      ).thenAnswer(
        (_) async => const Result.success(
          StartActionOutcome.started(
            runningId: 10,
            effects: [
              TransitionEffect.pomodoroShouldStop(reason: PomodoroStopReason.secondPomodoro),
              TransitionEffect.pomodoroShouldStart(
                actionNameId: 1,
                historyId: 100,
                pomodoroType: PomodoroType.normal,
              ),
            ],
          ),
        ),
      );
    },
    act: (bloc) => bloc.add(const ActionEvent.startConfirmed(1)),
    expect: () => [
      const ActionState.loaded(
        lastTransition: TransitionEffect.pomodoroShouldStop(
          reason: PomodoroStopReason.secondPomodoro,
        ),
      ),
      const ActionState.loaded(
        lastTransition: TransitionEffect.pomodoroShouldStart(
          actionNameId: 1,
          historyId: 100,
          pomodoroType: PomodoroType.normal,
        ),
      ),
    ],
  );

  blocTest<ActionBloc, ActionState>(
    'pause emits pomodoroShouldStop effect',
    build: build,
    setUp: () {
      when(() => pause(10)).thenAnswer(
        (_) async => const Result.success([
          TransitionEffect.pomodoroShouldStop(reason: PomodoroStopReason.pausedByUser),
        ]),
      );
    },
    act: (bloc) => bloc.add(const ActionEvent.paused(10)),
    expect: () => [
      const ActionState.loaded(
        lastTransition: TransitionEffect.pomodoroShouldStop(
          reason: PomodoroStopReason.pausedByUser,
        ),
      ),
    ],
  );

  blocTest<ActionBloc, ActionState>(
    'stop emits effects and transitionHandled clears them',
    build: build,
    setUp: () {
      when(() => stop(10)).thenAnswer(
        (_) async => const Result.success([
          TransitionEffect.pomodoroShouldStop(reason: PomodoroStopReason.stoppedByUser),
        ]),
      );
    },
    act: (bloc) => bloc
      ..add(const ActionEvent.stopped(10))
      ..add(const ActionEvent.transitionHandled()),
    expect: () => [
      const ActionState.loaded(
        lastTransition: TransitionEffect.pomodoroShouldStop(
          reason: PomodoroStopReason.stoppedByUser,
        ),
      ),
      const ActionState.loaded(),
    ],
  );

  blocTest<ActionBloc, ActionState>(
    'failure emits error state then recovers to data',
    build: build,
    setUp: () {
      when(
        () => stop(10),
      ).thenAnswer((_) async => const Result.failure(ActionFailure('running not found')));
    },
    act: (bloc) => bloc.add(const ActionEvent.stopped(10)),
    wait: const Duration(milliseconds: 20),
    expect: () => [
      const ActionState.error(ActionFailure('running not found')),
      const ActionState.loaded(),
    ],
  );
}
