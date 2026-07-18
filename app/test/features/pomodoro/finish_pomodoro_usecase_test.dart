import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_session_entity.dart';
import 'package:timefocus/features/pomodoro/domain/entities/pomodoro_settings_entity.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_repository.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_settings_repository.dart';
import 'package:timefocus/features/pomodoro/domain/usecases/finish_pomodoro_interval_usecase.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/pomodoro_after_action.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';

class _MockPomodoroRepository extends Mock implements PomodoroRepository {}

class _MockPomodoroSettingsRepository extends Mock implements PomodoroSettingsRepository {}

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

const workNoBreak = ActionNameEntity(
  id: 3,
  name: 'work-no-break',
  color: 0,
  icon: 0,
  mode: ActionMode.pomodoro,
  pomodoroType: PomodoroType.normal,
);

PomodoroSessionEntity session({int cycleNumber = 1, int actionHistoryId = 100}) =>
    PomodoroSessionEntity(
      id: 5,
      actionNameId: work.id,
      actionHistoryId: actionHistoryId,
      settingsId: 1,
      type: PomodoroType.normal,
      plannedTime: 1500,
      startTime: now.subtract(const Duration(minutes: 25)),
      cycleNumber: cycleNumber,
    );

PomodoroSettingsEntity settings({
  PomodoroAfterAction afterAction = PomodoroAfterAction.doNothing,
  int cyclesBeforeLongBreak = 4,
}) => PomodoroSettingsEntity(
  id: 1,
  afterAction: afterAction,
  cyclesBeforeLongBreak: cyclesBeforeLongBreak,
  createdAt: now,
);

void main() {
  setUpAll(() {
    registerFallbackValue(PomodoroStatus.completed);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(PomodoroType.normal);
  });

  late _MockPomodoroRepository sessions;
  late _MockPomodoroSettingsRepository settingsRepo;
  late FinishPomodoroIntervalUseCase usecase;

  setUp(() {
    sessions = _MockPomodoroRepository();
    settingsRepo = _MockPomodoroSettingsRepository();
    usecase = FinishPomodoroIntervalUseCase(sessions, settingsRepo);
    when(
      () => sessions.finish(any(), any(), any()),
    ).thenAnswer((_) async => const Result.success(null));
  });

  test('marks the session completed', () async {
    when(() => settingsRepo.current()).thenAnswer((_) async => Result.success(settings()));
    await usecase(workSession: session(), workAction: work, now: now);
    verify(() => sessions.finish(5, PomodoroStatus.completed, now)).called(1);
  });

  group('cycle progression (FR-014)', () {
    test('cycle < cyclesBeforeLongBreak → short break, cycle+1', () async {
      when(
        () => settingsRepo.current(),
      ).thenAnswer(
        (_) async => Result.success(settings(afterAction: PomodoroAfterAction.autoStartBreak)),
      );
      final result = await usecase(
        workSession: session(cycleNumber: 3),
        workAction: work,
        now: now,
      );
      final outcome = result.valueOrNull! as FinishStartBreak;
      expect(outcome.isLong, isFalse);
      expect(outcome.nextCycle, 4);
    });

    test('cycle == cyclesBeforeLongBreak → long break, cycle resets to 1', () async {
      when(
        () => settingsRepo.current(),
      ).thenAnswer(
        (_) async => Result.success(settings(afterAction: PomodoroAfterAction.autoStartBreak)),
      );
      final result = await usecase(
        workSession: session(cycleNumber: 4),
        workAction: work,
        now: now,
      );
      final outcome = result.valueOrNull! as FinishStartBreak;
      expect(outcome.isLong, isTrue);
      expect(outcome.nextCycle, 1);
    });

    test('cyclesBeforeLongBreak == 3 (min) triggers long break at 3', () async {
      when(() => settingsRepo.current()).thenAnswer(
        (_) async => Result.success(
          settings(afterAction: PomodoroAfterAction.autoStartBreak, cyclesBeforeLongBreak: 3),
        ),
      );
      final result = await usecase(
        workSession: session(cycleNumber: 3),
        workAction: work,
        now: now,
      );
      expect((result.valueOrNull! as FinishStartBreak).isLong, isTrue);
    });

    test('cyclesBeforeLongBreak == 5 (max) does not long-break at 4', () async {
      when(() => settingsRepo.current()).thenAnswer(
        (_) async => Result.success(
          settings(afterAction: PomodoroAfterAction.autoStartBreak, cyclesBeforeLongBreak: 5),
        ),
      );
      final result = await usecase(
        workSession: session(cycleNumber: 4),
        workAction: work,
        now: now,
      );
      final outcome = result.valueOrNull! as FinishStartBreak;
      expect(outcome.isLong, isFalse);
      expect(outcome.nextCycle, 5);
    });
  });

  group('afterAction (FR-018)', () {
    test('doNothing → idle, carries nextCycle', () async {
      when(
        () => settingsRepo.current(),
      ).thenAnswer((_) async => Result.success(settings()));
      final result = await usecase(
        workSession: session(cycleNumber: 2),
        workAction: work,
        now: now,
      );
      expect(result.valueOrNull, const FinishPomodoroOutcome.idle(nextCycle: 3));
    });

    test('autoStartBreak → startBreak with breakActionId', () async {
      when(() => settingsRepo.current()).thenAnswer(
        (_) async => Result.success(settings(afterAction: PomodoroAfterAction.autoStartBreak)),
      );
      final result = await usecase(workSession: session(), workAction: work, now: now);
      expect(
        result.valueOrNull,
        const FinishPomodoroOutcome.startBreak(breakActionId: 2, nextCycle: 2, isLong: false),
      );
    });

    test('autoStartBreak without a configured break activity → idle', () async {
      when(() => settingsRepo.current()).thenAnswer(
        (_) async => Result.success(settings(afterAction: PomodoroAfterAction.autoStartBreak)),
      );
      final result = await usecase(
        workSession: session(),
        workAction: workNoBreak,
        now: now,
      );
      expect(result.valueOrNull, const FinishPomodoroOutcome.idle(nextCycle: 2));
    });

    test('suggestBreak → breakSuggested, nothing started', () async {
      when(() => settingsRepo.current()).thenAnswer(
        (_) async => Result.success(settings(afterAction: PomodoroAfterAction.suggestBreak)),
      );
      final result = await usecase(workSession: session(), workAction: work, now: now);
      expect(
        result.valueOrNull,
        const FinishPomodoroOutcome.breakSuggested(breakActionId: 2, nextCycle: 2, isLong: false),
      );
      verifyNever(
        () => sessions.startSession(
          actionNameId: any(named: 'actionNameId'),
          historyId: any(named: 'historyId'),
          type: any(named: 'type'),
          cycleNumber: any(named: 'cycleNumber'),
          isBreak: any(named: 'isBreak'),
        ),
      );
    });

    test('repeatSame → new work session with the SAME cycle number', () async {
      when(() => settingsRepo.current()).thenAnswer(
        (_) async => Result.success(settings(afterAction: PomodoroAfterAction.repeatSame)),
      );
      when(
        () => sessions.startSession(
          actionNameId: work.id,
          historyId: 100,
          type: PomodoroType.normal,
          cycleNumber: 2,
          isBreak: false,
        ),
      ).thenAnswer((_) async => Result.success(session(cycleNumber: 2)));
      final result = await usecase(
        workSession: session(cycleNumber: 2),
        workAction: work,
        now: now,
      );
      expect(result.valueOrNull, isA<FinishWorkRestarted>());
      verify(
        () => sessions.startSession(
          actionNameId: work.id,
          historyId: 100,
          type: PomodoroType.normal,
          cycleNumber: 2,
          isBreak: false,
        ),
      ).called(1);
    });

    test('autoStartWork → new work session with the NEXT cycle number', () async {
      when(() => settingsRepo.current()).thenAnswer(
        (_) async => Result.success(settings(afterAction: PomodoroAfterAction.autoStartWork)),
      );
      when(
        () => sessions.startSession(
          actionNameId: work.id,
          historyId: 100,
          type: PomodoroType.normal,
          cycleNumber: 3,
          isBreak: false,
        ),
      ).thenAnswer((_) async => Result.success(session(cycleNumber: 3)));
      final result = await usecase(
        workSession: session(cycleNumber: 2),
        workAction: work,
        now: now,
      );
      expect(result.valueOrNull, isA<FinishWorkRestarted>());
      verify(
        () => sessions.startSession(
          actionNameId: work.id,
          historyId: 100,
          type: PomodoroType.normal,
          cycleNumber: 3,
          isBreak: false,
        ),
      ).called(1);
    });
  });
}
