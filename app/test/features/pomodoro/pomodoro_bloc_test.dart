import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_session_entity.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_settings_entity.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_repository.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_settings_repository.dart';
import 'package:timefocus/features/pomodoro/domain/usecases/finish_pomodoro_interval_usecase.dart';
import 'package:timefocus/features/pomodoro/presentation/bloc/pomodoro_bloc.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/notification_type.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

class _MockPomodoroRepository extends Mock implements PomodoroRepository {}

class _MockPomodoroSettingsRepository extends Mock implements PomodoroSettingsRepository {}

class _MockActionNameRepository extends Mock implements ActionNameRepository {}

class _MockFinishInterval extends Mock implements FinishPomodoroIntervalUseCase {}

class _MockScheduler extends Mock implements NotificationScheduler {}

final now = DateTime(2026, 7, 18, 10);

const work = ActionNameEntity(
  id: 1,
  name: 'work',
  color: 0,
  icon: 0,
  mode: ActionMode.pomodoro,
  pomodoroType: PomodoroType.normal,
  breakActionId: 2,
);

const breakAction = ActionNameEntity(
  id: 2,
  name: 'break',
  color: 0,
  icon: 0,
  mode: ActionMode.breakFor,
);

PomodoroSessionEntity workSession({int id = 5, int cycleNumber = 1}) => PomodoroSessionEntity(
  id: id,
  actionNameId: work.id,
  actionHistoryId: 100,
  settingsId: 1,
  type: PomodoroType.normal,
  plannedTime: 1500,
  startTime: now,
  cycleNumber: cycleNumber,
);

PomodoroSessionEntity breakSession({int id = 6, int cycleNumber = 1}) => PomodoroSessionEntity(
  id: id,
  actionNameId: breakAction.id,
  actionHistoryId: 200,
  settingsId: 1,
  type: PomodoroType.short,
  plannedTime: 300,
  startTime: now,
  cycleNumber: cycleNumber,
);

PomodoroSettingsEntity settings({int cyclesBeforeLongBreak = 4}) =>
    PomodoroSettingsEntity(id: 1, cyclesBeforeLongBreak: cyclesBeforeLongBreak, createdAt: now);

void main() {
  setUpAll(() {
    registerFallbackValue(PomodoroStatus.completed);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(PomodoroType.normal);
    registerFallbackValue(NotificationType.pomodoroFinished);
    registerFallbackValue(
      NotificationDraft(
        type: NotificationType.pomodoroFinished,
        scheduledAt: now,
        title: '',
        body: '',
      ),
    );
    registerFallbackValue(workSession());
    registerFallbackValue(work);
  });

  late _MockPomodoroRepository sessions;
  late _MockPomodoroSettingsRepository settingsRepo;
  late _MockActionNameRepository actions;
  late _MockFinishInterval finishInterval;
  late _MockScheduler scheduler;

  setUp(() {
    sessions = _MockPomodoroRepository();
    settingsRepo = _MockPomodoroSettingsRepository();
    actions = _MockActionNameRepository();
    finishInterval = _MockFinishInterval();
    scheduler = _MockScheduler();

    when(() => settingsRepo.current()).thenAnswer((_) async => Result.success(settings()));
    when(() => actions.getById(work.id)).thenAnswer((_) async => const Result.success(work));
    when(
      () => actions.getById(breakAction.id),
    ).thenAnswer((_) async => const Result.success(breakAction));
    when(
      () => scheduler.schedule(any()),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => scheduler.cancelByType(any()),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => sessions.finish(any(), any(), any()),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => sessions.lastSessionForAction(any()),
    ).thenAnswer((_) async => const Result.success(null));
  });

  PomodoroBloc build() => PomodoroBloc(sessions, settingsRepo, actions, finishInterval, scheduler);

  blocTest<PomodoroBloc, PomodoroState>(
    'started → workRunning',
    build: build,
    setUp: () {
      when(
        () => sessions.startSession(
          actionNameId: work.id,
          historyId: 100,
          type: PomodoroType.normal,
          cycleNumber: 1,
          isBreak: false,
        ),
      ).thenAnswer((_) async => Result.success(workSession()));
    },
    act: (bloc) => bloc.add(
      const PomodoroEvent.started(actionNameId: 1, historyId: 100, type: PomodoroType.normal),
    ),
    expect: () => [
      PomodoroState.workRunning(
        session: workSession(),
        endsAt: now.add(const Duration(seconds: 1500)),
        cyclesBeforeLongBreak: 4,
      ),
    ],
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'work finished with autoStartBreak outcome → breakShouldStart → breakRunning',
    build: build,
    seed: () => PomodoroState.workRunning(
      session: workSession(),
      endsAt: now,
      cyclesBeforeLongBreak: 4,
    ),
    setUp: () {
      when(
        () => finishInterval(
          workSession: any(named: 'workSession'),
          workAction: any(named: 'workAction'),
        ),
      ).thenAnswer(
        (_) async => const Result.success(
          FinishPomodoroOutcome.startBreak(breakActionId: 2, nextCycle: 2, isLong: false),
        ),
      );
      when(
        () => sessions.startSession(
          actionNameId: breakAction.id,
          historyId: 300,
          type: PomodoroType.short,
          cycleNumber: 2,
          isBreak: true,
        ),
      ).thenAnswer((_) async => Result.success(breakSession(cycleNumber: 2)));
    },
    act: (bloc) async {
      bloc.add(const PomodoroEvent.workIntervalFinished(5));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const PomodoroEvent.breakActivityStarted(300));
    },
    expect: () => [
      const PomodoroState.breakShouldStart(
        breakActionId: 2,
        parentActionId: 1,
        nextCycle: 2,
        isLong: false,
      ),
      PomodoroState.breakRunning(
        session: breakSession(cycleNumber: 2),
        endsAt: now.add(const Duration(seconds: 300)),
        parentActionId: 1,
      ),
    ],
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'work finished with doNothing outcome → idle',
    build: build,
    seed: () => PomodoroState.workRunning(
      session: workSession(),
      endsAt: now,
      cyclesBeforeLongBreak: 4,
    ),
    setUp: () {
      when(
        () => finishInterval(
          workSession: any(named: 'workSession'),
          workAction: any(named: 'workAction'),
        ),
      ).thenAnswer((_) async => const Result.success(FinishPomodoroOutcome.idle(nextCycle: 2)));
    },
    act: (bloc) => bloc.add(const PomodoroEvent.workIntervalFinished(5)),
    expect: () => [const PomodoroState.idle()],
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'breakFinished → readyToResumeWork',
    build: build,
    seed: () => PomodoroState.breakRunning(
      session: breakSession(cycleNumber: 3),
      endsAt: now,
      parentActionId: 1,
    ),
    act: (bloc) => bloc.add(const PomodoroEvent.breakFinished(6)),
    expect: () => [const PomodoroState.readyToResumeWork(parentActionId: 1, nextCycle: 3)],
    verify: (_) {
      verify(() => sessions.finish(6, PomodoroStatus.completed, any())).called(1);
    },
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'interrupted (pausedByOthers) → idle, session marked interrupted',
    build: build,
    seed: () => PomodoroState.workRunning(
      session: workSession(),
      endsAt: now,
      cyclesBeforeLongBreak: 4,
    ),
    act: (bloc) => bloc.add(const PomodoroEvent.interrupted(PomodoroStopReason.pausedByOthers)),
    expect: () => [const PomodoroState.idle()],
    verify: (_) {
      verify(() => sessions.finish(5, PomodoroStatus.interrupted, any())).called(1);
    },
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'interrupted (stoppedByUser) resets the cycle for the next manual start',
    build: build,
    seed: () => PomodoroState.workRunning(
      session: workSession(cycleNumber: 3),
      endsAt: now,
      cyclesBeforeLongBreak: 4,
    ),
    setUp: () {
      // The DB still has cycle 3 as the last session — the in-memory reset
      // must win over it (FR-014: reset only on Stop).
      when(
        () => sessions.lastSessionForAction(work.id),
      ).thenAnswer((_) async => Result.success(workSession(cycleNumber: 3)));
      when(
        () => sessions.startSession(
          actionNameId: work.id,
          historyId: 100,
          type: PomodoroType.normal,
          cycleNumber: 1,
          isBreak: false,
        ),
      ).thenAnswer((_) async => Result.success(workSession()));
    },
    act: (bloc) async {
      bloc.add(const PomodoroEvent.interrupted(PomodoroStopReason.stoppedByUser));
      // interrupted/started are independent event streams (different
      // transformers) — wait for the reset to land before the next start.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(
        const PomodoroEvent.started(actionNameId: 1, historyId: 100, type: PomodoroType.normal),
      );
    },
    verify: (_) {
      verify(
        () => sessions.startSession(
          actionNameId: work.id,
          historyId: 100,
          type: PomodoroType.normal,
          cycleNumber: 1,
          isBreak: false,
        ),
      ).called(1);
    },
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'skipped while working → idle',
    build: build,
    seed: () => PomodoroState.workRunning(
      session: workSession(),
      endsAt: now,
      cyclesBeforeLongBreak: 4,
    ),
    act: (bloc) => bloc.add(const PomodoroEvent.skipped()),
    expect: () => [const PomodoroState.idle()],
    verify: (_) {
      verify(() => sessions.finish(5, PomodoroStatus.skipped, any())).called(1);
    },
  );

  blocTest<PomodoroBloc, PomodoroState>(
    'skipped while on break → readyToResumeWork',
    build: build,
    seed: () => PomodoroState.breakRunning(
      session: breakSession(cycleNumber: 2),
      endsAt: now,
      parentActionId: 1,
    ),
    act: (bloc) => bloc.add(const PomodoroEvent.skipped()),
    expect: () => [const PomodoroState.readyToResumeWork(parentActionId: 1, nextCycle: 2)],
  );
}
