import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/history/domain/entities/history_header_entity.dart';
import 'package:timefocus/features/history/domain/repositories/history_repository.dart';
import 'package:timefocus/features/history/presentation/cubit/history_cubit.dart';
import 'package:timefocus/shared/enums/history_mode.dart';
import 'package:timefocus/shared/enums/history_period.dart';

class _MockHistoryRepository extends Mock implements HistoryRepository {}

const header = HistoryHeaderEntity(totalSec: 3600, pomodoroCompleted: 2, waterDrankMl: 500);

void main() {
  late _MockHistoryRepository repository;

  setUp(() {
    repository = _MockHistoryRepository();
    when(
      () => repository.header(any(), any()),
    ).thenAnswer((_) async => const Result.success(header));
    when(() => repository.watchIntervals(any(), any())).thenAnswer((_) => Stream.value(const []));
    when(() => repository.watchTotals(any(), any())).thenAnswer((_) => Stream.value(const []));
  });

  HistoryCubit build() => HistoryCubit(repository);

  blocTest<HistoryCubit, HistoryState>(
    "subscribe loads the header and today's intervals by default",
    build: build,
    act: (cubit) => cubit.subscribe(),
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final state = cubit.state as HistoryLoaded;
      expect(state.mode, HistoryMode.intervals);
      expect(state.period, HistoryPeriod.day);
      expect(state.header, header);
      expect(state.intervals, isEmpty);
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'setMode(totals) switches to the totals stream',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      cubit.setMode(HistoryMode.totals);
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final state = cubit.state as HistoryLoaded;
      expect(state.mode, HistoryMode.totals);
      verify(() => repository.watchTotals(any(), any())).called(greaterThan(0));
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'setMode(stats) shows only the header — statistics mode is a placeholder',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      cubit.setMode(HistoryMode.stats);
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final state = cubit.state as HistoryLoaded;
      expect(state.mode, HistoryMode.stats);
      expect(state.header, header);
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'stepNext/stepPrevious move the day anchor',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      cubit.stepNext();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final state = cubit.state as HistoryLoaded;
      final now = DateTime.now();
      expect(state.anchor.difference(now).inHours, closeTo(24, 1));
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'goToToday resets the anchor after navigating away',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      cubit
        ..stepNext()
        ..stepNext()
        ..goToToday();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final state = cubit.state as HistoryLoaded;
      final now = DateTime.now();
      expect(state.anchor.difference(now).inHours.abs(), lessThan(1));
    },
  );

  blocTest<HistoryCubit, HistoryState>(
    'a repository failure surfaces as an error state',
    build: build,
    setUp: () => when(
      () => repository.header(any(), any()),
    ).thenAnswer((_) async => const Result.failure(DatabaseFailure('boom'))),
    act: (cubit) => cubit.subscribe(),
    expect: () => [isA<HistoryError>()],
  );
}
