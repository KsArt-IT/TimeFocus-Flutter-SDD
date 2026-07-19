import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/data/datasources/local_notifications_datasource.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_intent.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/notifications/domain/usecases/handle_notification_tap_usecase.dart';
import 'package:timefocus/features/notifications/presentation/bloc/notification_bloc.dart';

class _MockLocal extends Mock implements LocalNotificationsDataSource {}

class _MockScheduler extends Mock implements NotificationScheduler {}

class _MockHandleTap extends Mock implements HandleNotificationTapUseCase {}

void main() {
  late _MockLocal local;
  late _MockScheduler scheduler;
  late _MockHandleTap handleTap;

  setUp(() {
    local = _MockLocal();
    scheduler = _MockScheduler();
    handleTap = _MockHandleTap();

    when(() => local.taps).thenAnswer((_) => const Stream.empty());
    when(() => local.launchDetails()).thenAnswer((_) async => null);
    when(() => scheduler.rescheduleAll()).thenAnswer((_) async => const Result.success(null));
    when(() => scheduler.flushDeferred()).thenAnswer((_) async => const Result.success(null));
    when(
      () => handleTap(
        payloadJson: any(named: 'payloadJson'),
        actionId: any(named: 'actionId'),
      ),
    ).thenReturn(const NotificationIntent.openTracker());
  });

  NotificationBloc build() => NotificationBloc(local, scheduler, handleTap);

  blocTest<NotificationBloc, NotificationState>(
    'initialized with no cold-start launch: rescheduleAll runs, no pending intent',
    build: build,
    act: (bloc) => bloc.add(const NotificationEvent.initialized()),
    expect: () => <NotificationState>[],
    verify: (bloc) {
      verify(() => scheduler.rescheduleAll()).called(1);
      expect(bloc.state.pendingIntent, isNull);
    },
  );

  blocTest<NotificationBloc, NotificationState>(
    'initialized with a cold-start launch decodes an intent (SC-003)',
    build: build,
    setUp: () {
      when(() => local.launchDetails()).thenAnswer(
        (_) async => const NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: 'cold-start-payload',
        ),
      );
      when(
        // mocktail needs the explicit named arg to match the SUT's call shape.
        () => handleTap(
          payloadJson: 'cold-start-payload',
          actionId: null, // ignore: avoid_redundant_argument_values
        ),
      ).thenReturn(const NotificationIntent.resumeWork(7));
    },
    act: (bloc) => bloc.add(const NotificationEvent.initialized()),
    expect: () => [const NotificationState(pendingIntent: NotificationIntent.resumeWork(7))],
  );

  blocTest<NotificationBloc, NotificationState>(
    'a warm tap decodes to a pending intent',
    build: build,
    setUp: () => when(
      () => handleTap(payloadJson: 'p', actionId: 'extendBreak'),
    ).thenReturn(const NotificationIntent.extendBreak(5)),
    act: (bloc) => bloc.add(const NotificationEvent.tapped(payload: 'p', actionId: 'extendBreak')),
    expect: () => [const NotificationState(pendingIntent: NotificationIntent.extendBreak(5))],
  );

  blocTest<NotificationBloc, NotificationState>(
    'intentHandled clears the pending intent',
    build: build,
    seed: () => const NotificationState(pendingIntent: NotificationIntent.openTracker()),
    act: (bloc) => bloc.add(const NotificationEvent.intentHandled()),
    expect: () => [const NotificationState()],
  );

  blocTest<NotificationBloc, NotificationState>(
    'scheduleRecalculated flushes the deferred queue',
    build: build,
    act: (bloc) =>
        bloc.add(const NotificationEvent.scheduleRecalculated(ScheduleRecalcTrigger.pomodoroEnded)),
    expect: () => <NotificationState>[],
    verify: (_) {
      verify(() => scheduler.flushDeferred()).called(1);
    },
  );

  blocTest<NotificationBloc, NotificationState>(
    'a tap arriving on the taps stream is handled the same way',
    build: () {
      when(() => local.taps).thenAnswer(
        (_) => Stream.value(
          const NotificationResponse(
            notificationResponseType: NotificationResponseType.selectedNotification,
            payload: 'warm-payload',
          ),
        ),
      );
      when(
        // mocktail needs the explicit named arg to match the SUT's call shape.
        () => handleTap(
          payloadJson: 'warm-payload',
          actionId: null, // ignore: avoid_redundant_argument_values
        ),
      ).thenReturn(const NotificationIntent.startAction(3));
      return build();
    },
    wait: const Duration(milliseconds: 20),
    expect: () => [const NotificationState(pendingIntent: NotificationIntent.startAction(3))],
  );
}
