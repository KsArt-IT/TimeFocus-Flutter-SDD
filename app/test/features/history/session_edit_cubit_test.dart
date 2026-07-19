import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/history/domain/repositories/history_repository.dart';
import 'package:timefocus/features/history/presentation/cubit/session_edit_cubit.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_running_repository.dart';
import 'package:timefocus/shared/enums/action_status.dart';

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockActionNameRepository extends Mock implements ActionNameRepository {}

class _MockActionRunningRepository extends Mock implements ActionRunningRepository {}

const _actionNameId = 7;
const _historyId = 42;

const _action = ActionNameEntity(
  id: _actionNameId,
  name: 'Reading',
  color: 0xFF000000,
  icon: 0,
);

final _session = HistorySessionEntity(
  historyId: _historyId,
  actionNameId: _actionNameId,
  date: DateTime.now(),
);

final _at = DateTime(2026, 7, 19, 12);

RunningWithNameEntity _running({required ActionStatus status, required int runningId}) =>
    RunningWithNameEntity(
      runningId: runningId,
      historyId: _historyId,
      action: _action,
      status: status,
      startedAt: DateTime.now(),
    );

void main() {
  late _MockHistoryRepository history;
  late _MockActionNameRepository actions;
  late _MockActionRunningRepository runnings;

  setUp(() {
    history = _MockHistoryRepository();
    actions = _MockActionNameRepository();
    runnings = _MockActionRunningRepository();

    when(() => history.session(_historyId)).thenAnswer((_) async => Result.success(_session));
    when(() => actions.watchGrid()).thenAnswer((_) => Stream.value([_action]));
  });

  SessionEditCubit build() => SessionEditCubit(history, actions, runnings);

  void stubCurrentRunning(RunningWithNameEntity? running) {
    when(
      () => runnings.currentRunning(),
    ).thenAnswer((_) async => Result.success(running == null ? [] : [running]));
  }

  blocTest<SessionEditCubit, SessionEditState>(
    'stopped → active starts a new running row at the staged time, no interval',
    setUp: () {
      stubCurrentRunning(null);
      when(
        () => runnings.start(actionNameId: _actionNameId, now: _at),
      ).thenAnswer((_) async => const Result.success(1));
    },
    build: build,
    act: (cubit) async {
      await cubit.load(_historyId);
      await cubit.commitRunningStatus(target: ActionStatus.active, at: _at);
    },
    verify: (_) {
      verify(() => runnings.start(actionNameId: _actionNameId, now: _at)).called(1);
      verifyNever(() => runnings.pause(any(), any()));
      verifyNever(() => runnings.stop(any(), any()));
    },
  );

  blocTest<SessionEditCubit, SessionEditState>(
    'stopped → paused creates a paused row without ever inserting an interval',
    setUp: () {
      stubCurrentRunning(null);
      when(
        () => runnings.startPaused(actionNameId: _actionNameId, now: _at),
      ).thenAnswer((_) async => const Result.success(1));
    },
    build: build,
    act: (cubit) async {
      await cubit.load(_historyId);
      await cubit.commitRunningStatus(target: ActionStatus.pause, at: _at);
    },
    verify: (_) {
      verify(() => runnings.startPaused(actionNameId: _actionNameId, now: _at)).called(1);
      verifyNever(
        () => runnings.start(
          actionNameId: any(named: 'actionNameId'),
          now: any(named: 'now'),
        ),
      );
    },
  );

  blocTest<SessionEditCubit, SessionEditState>(
    'active → paused only closes the open interval via pause, never stop+start',
    setUp: () {
      stubCurrentRunning(_running(status: ActionStatus.active, runningId: 5));
      when(() => runnings.pause(5, _at)).thenAnswer((_) async => const Result.success(null));
    },
    build: build,
    act: (cubit) async {
      await cubit.load(_historyId);
      await cubit.commitRunningStatus(target: ActionStatus.pause, at: _at);
    },
    verify: (_) {
      verify(() => runnings.pause(5, _at)).called(1);
      verifyNever(() => runnings.stop(any(), any()));
      verifyNever(
        () => runnings.start(
          actionNameId: any(named: 'actionNameId'),
          now: any(named: 'now'),
        ),
      );
    },
  );

  blocTest<SessionEditCubit, SessionEditState>(
    'paused → active resumes the same row instead of starting a new one',
    setUp: () {
      stubCurrentRunning(_running(status: ActionStatus.pause, runningId: 5));
      when(() => runnings.resume(5, _at)).thenAnswer((_) async => const Result.success(null));
    },
    build: build,
    act: (cubit) async {
      await cubit.load(_historyId);
      await cubit.commitRunningStatus(target: ActionStatus.active, at: _at);
    },
    verify: (_) {
      verify(() => runnings.resume(5, _at)).called(1);
      verifyNever(
        () => runnings.start(
          actionNameId: any(named: 'actionNameId'),
          now: any(named: 'now'),
        ),
      );
    },
  );

  blocTest<SessionEditCubit, SessionEditState>(
    'active → stopped closes via stop only — no extra interval is inserted',
    setUp: () {
      stubCurrentRunning(_running(status: ActionStatus.active, runningId: 5));
      when(() => runnings.stop(5, _at)).thenAnswer((_) async => const Result.success(null));
    },
    build: build,
    act: (cubit) async {
      await cubit.load(_historyId);
      await cubit.commitRunningStatus(target: ActionStatus.stop, at: _at);
    },
    verify: (_) {
      verify(() => runnings.stop(5, _at)).called(1);
      verifyNever(() => runnings.pause(any(), any()));
    },
  );

  blocTest<SessionEditCubit, SessionEditState>(
    'paused → stopped just deletes the row — pause is not called again',
    setUp: () {
      stubCurrentRunning(_running(status: ActionStatus.pause, runningId: 5));
      when(() => runnings.stop(5, _at)).thenAnswer((_) async => const Result.success(null));
    },
    build: build,
    act: (cubit) async {
      await cubit.load(_historyId);
      await cubit.commitRunningStatus(target: ActionStatus.stop, at: _at);
    },
    verify: (_) {
      verify(() => runnings.stop(5, _at)).called(1);
      verifyNever(() => runnings.pause(any(), any()));
    },
  );

  blocTest<SessionEditCubit, SessionEditState>(
    'committing the already-current status is a no-op — nothing is written',
    setUp: () => stubCurrentRunning(_running(status: ActionStatus.active, runningId: 5)),
    build: build,
    act: (cubit) async {
      await cubit.load(_historyId);
      await cubit.commitRunningStatus(target: ActionStatus.active, at: _at);
    },
    verify: (_) {
      verifyNever(() => runnings.pause(any(), any()));
      verifyNever(() => runnings.resume(any(), any()));
      verifyNever(() => runnings.stop(any(), any()));
      verifyNever(
        () => runnings.start(
          actionNameId: any(named: 'actionNameId'),
          now: any(named: 'now'),
        ),
      );
    },
  );
}
