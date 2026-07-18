import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/transition_effect.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_running_repository.dart';
import 'package:timefocus/features/tracker/domain/usecases/start_action_usecase.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/action_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

class _MockActionNameRepository extends Mock implements ActionNameRepository {}

class _MockActionRunningRepository extends Mock implements ActionRunningRepository {}

const work = ActionNameEntity(
  id: 1,
  name: 'work',
  color: 0,
  icon: 0,
  mode: ActionMode.pomodoro,
  pomodoroType: PomodoroType.normal,
  breakActionId: 2,
  isSystem: true,
);

const breakAction = ActionNameEntity(
  id: 2,
  name: 'break',
  color: 0,
  icon: 0,
  mode: ActionMode.breakFor,
  isSystem: true,
);

const toilet = ActionNameEntity(
  id: 3,
  name: 'toilet',
  color: 0,
  icon: 0,
  pauseOthers: true,
  isSystem: true,
);

const rest = ActionNameEntity(id: 4, name: 'rest', color: 0, icon: 0, isSystem: true);

const study = ActionNameEntity(
  id: 5,
  name: 'study',
  color: 0,
  icon: 0,
  mode: ActionMode.pomodoro,
  pomodoroType: PomodoroType.short,
);

final now = DateTime(2026, 7, 18, 10);

RunningWithNameEntity running(
  ActionNameEntity action, {
  int? runningId,
  ActionStatus status = ActionStatus.active,
  bool pausedBySystem = false,
}) => RunningWithNameEntity(
  runningId: runningId ?? action.id * 10,
  historyId: action.id * 100,
  action: action,
  status: status,
  startedAt: now.subtract(const Duration(minutes: 5)),
  pausedBySystem: pausedBySystem,
);

void main() {
  late _MockActionNameRepository actions;
  late _MockActionRunningRepository runnings;
  late StartActionUseCase usecase;

  setUp(() {
    actions = _MockActionNameRepository();
    runnings = _MockActionRunningRepository();
    usecase = StartActionUseCase(actions, runnings);

    for (final a in [work, breakAction, toilet, rest, study]) {
      when(() => actions.getById(a.id)).thenAnswer((_) async => Result.success(a));
    }
    when(
      () => runnings.start(
        actionNameId: any(named: 'actionNameId'),
        now: any(named: 'now'),
      ),
    ).thenAnswer((invocation) async {
      final id = invocation.namedArguments[#actionNameId] as int;
      return Result.success(id * 10);
    });
    when(
      () => runnings.pause(any(), any(), bySystem: any(named: 'bySystem')),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => runnings.resume(any(), any())).thenAnswer((_) async => const Result.success(null));
  });

  void withRunning(List<RunningWithNameEntity> list) {
    when(() => runnings.currentRunning()).thenAnswer((_) async => Result.success(list));
  }

  List<TransitionEffect> effectsOf(Result<StartActionOutcome> result) =>
      switch (result.valueOrNull) {
        StartStarted(:final effects) => effects,
        _ => fail('expected started, got ${result.valueOrNull}'),
      };

  group('shouldInterruptPomodoro', () {
    test('pomodoro, breakFor and pauseOthers interrupt on user transition', () {
      expect(usecase.shouldInterruptPomodoro(work, isSystemTransition: false), isTrue);
      expect(usecase.shouldInterruptPomodoro(breakAction, isSystemTransition: false), isTrue);
      expect(usecase.shouldInterruptPomodoro(toilet, isSystemTransition: false), isTrue);
      expect(usecase.shouldInterruptPomodoro(rest, isSystemTransition: false), isFalse);
    });

    test('system transition never interrupts', () {
      expect(usecase.shouldInterruptPomodoro(work, isSystemTransition: true), isFalse);
      expect(usecase.shouldInterruptPomodoro(breakAction, isSystemTransition: true), isFalse);
      expect(usecase.shouldInterruptPomodoro(toilet, isSystemTransition: true), isFalse);
    });
  });

  group('plain activity (nothing, no pauseOthers)', () {
    test('starts in parallel without effects while pomodoro is active', () async {
      withRunning([running(work)]);
      final result = await usecase(rest.id, now: now);
      expect(effectsOf(result), isEmpty);
      verify(() => runnings.start(actionNameId: rest.id, now: now)).called(1);
      verifyNever(() => runnings.pause(any(), any(), bySystem: any(named: 'bySystem')));
    });

    test('already active → noop', () async {
      withRunning([running(rest)]);
      final result = await usecase(rest.id, now: now);
      expect(result.valueOrNull, const StartActionOutcome.noop());
      verifyNever(
        () => runnings.start(
          actionNameId: any(named: 'actionNameId'),
          now: any(named: 'now'),
        ),
      );
    });
  });

  group('pomodoro start', () {
    test('idle → pomodoroShouldStart', () async {
      withRunning([]);
      final result = await usecase(work.id, now: now);
      final effects = effectsOf(result);
      expect(effects, [
        const TransitionEffect.pomodoroShouldStart(
          actionNameId: 1,
          historyId: 0,
          pomodoroType: PomodoroType.normal,
        ),
      ]);
    });

    test('second pomodoro without confirmation → needsConfirmation, nothing changes', () async {
      withRunning([running(work)]);
      final result = await usecase(study.id, now: now);
      expect(result.valueOrNull, const StartActionOutcome.needsConfirmation(study));
      verifyNever(
        () => runnings.start(
          actionNameId: any(named: 'actionNameId'),
          now: any(named: 'now'),
        ),
      );
      verifyNever(() => runnings.pause(any(), any(), bySystem: any(named: 'bySystem')));
    });

    test('second pomodoro confirmed → stop effect + pause previous + start', () async {
      withRunning([running(work)]);
      final result = await usecase(study.id, confirmed: true, now: now);
      final effects = effectsOf(result);
      expect(
        effects.first,
        const TransitionEffect.pomodoroShouldStop(reason: PomodoroStopReason.secondPomodoro),
      );
      expect(
        effects[1],
        const TransitionEffect.pomodoroInterrupted(byAction: study, interruptedAction: work),
      );
      expect(effects.last, isA<PomodoroShouldStart>());
      verify(() => runnings.pause(running(work).runningId, now)).called(1);
      verify(() => runnings.start(actionNameId: study.id, now: now)).called(1);
    });

    test('system resume of paused work does not interrupt and emits pomodoroShouldStart', () async {
      final pausedWork = running(work, status: ActionStatus.pause, pausedBySystem: true);
      withRunning([pausedWork]);
      final result = await usecase(work.id, source: ActionStartSource.system, now: now);
      final effects = effectsOf(result);
      expect(effects.whereType<PomodoroShouldStop>(), isEmpty);
      expect(effects.single, isA<PomodoroShouldStart>());
      verify(() => runnings.resume(pausedWork.runningId, now)).called(1);
    });
  });

  group('manual break (breakFor)', () {
    test('interrupts pomodoro and pauses work bySystem', () async {
      final workRun = running(work);
      withRunning([workRun]);
      final result = await usecase(breakAction.id, now: now);
      final effects = effectsOf(result);
      expect(
        effects.first,
        const TransitionEffect.pomodoroShouldStop(reason: PomodoroStopReason.manualBreak),
      );
      expect(effects.last, const TransitionEffect.breakStarted(breakActionId: 2, historyId: 0));
      verify(() => runnings.pause(workRun.runningId, now, bySystem: true)).called(1);
    });

    test('system break start after work completion → no stop effect', () async {
      final workRun = running(work);
      withRunning([workRun]);
      final result = await usecase(breakAction.id, source: ActionStartSource.system, now: now);
      final effects = effectsOf(result);
      expect(effects.whereType<PomodoroShouldStop>(), isEmpty);
      expect(effects.single, const TransitionEffect.breakStarted(breakActionId: 2, historyId: 0));
      verify(() => runnings.pause(workRun.runningId, now, bySystem: true)).called(1);
    });
  });

  group('pauseOthers', () {
    test('while pomodoro active: interrupts and pauses everything bySystem', () async {
      final workRun = running(work);
      final restRun = running(rest);
      withRunning([workRun, restRun]);
      final result = await usecase(toilet.id, now: now);
      final effects = effectsOf(result);
      expect(
        effects.first,
        const TransitionEffect.pomodoroShouldStop(reason: PomodoroStopReason.pausedByOthers),
      );
      verify(() => runnings.pause(workRun.runningId, now, bySystem: true)).called(1);
      verify(() => runnings.pause(restRun.runningId, now, bySystem: true)).called(1);
      verify(() => runnings.start(actionNameId: toilet.id, now: now)).called(1);
    });

    test('during break: break activity and cycle untouched (FR-010b)', () async {
      final breakRun = running(breakAction);
      final restRun = running(rest);
      withRunning([breakRun, restRun]);
      final result = await usecase(toilet.id, now: now);
      final effects = effectsOf(result);
      // No active pomodoro work interval → no stop effect.
      expect(effects.whereType<PomodoroShouldStop>(), isEmpty);
      verifyNever(
        () => runnings.pause(breakRun.runningId, any(), bySystem: any(named: 'bySystem')),
      );
      verify(() => runnings.pause(restRun.runningId, now, bySystem: true)).called(1);
    });

    test('system start of pauseOthers still pauses others but no interrupt effect', () async {
      final workRun = running(work);
      withRunning([workRun]);
      final result = await usecase(toilet.id, source: ActionStartSource.system, now: now);
      final effects = effectsOf(result);
      expect(effects.whereType<PomodoroShouldStop>(), isEmpty);
      verify(() => runnings.pause(workRun.runningId, now, bySystem: true)).called(1);
    });
  });
}
