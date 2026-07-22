import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/water/domain/entities/day_schedule_times_entity.dart';
import 'package:timefocus/features/water/domain/entities/hud_queue_item_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/features/water/domain/repositories/hud_queue_repository.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/features/water/domain/usecases/log_water_usecase.dart';
import 'package:timefocus/features/water/domain/usecases/plan_water_reminders_usecase.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_cubit.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

class _MockWaterRepository extends Mock implements WaterRepository {}

class _MockLogWater extends Mock implements LogWaterUseCase {}

class _MockPlanReminders extends Mock implements PlanWaterRemindersUseCase {}

class _MockScheduler extends Mock implements NotificationScheduler {}

/// A tiny stateful in-memory stand-in for the DB-backed queue — a Mock alone
/// can't react to `raise`/`dismiss` the way the real DAO does.
class _FakeHudQueueRepository implements HudQueueRepository {
  final _rows = <int, ({SystemAction action, DateTime day, bool dismissed})>{};
  var _nextId = 1;

  void Function(List<HudQueueItemEntity>)? _listener;

  void _emit() {
    final active = _rows.entries
        .where((e) => !e.value.dismissed)
        .map((e) => HudQueueItemEntity(id: e.key, action: e.value.action))
        .toList();
    _listener?.call(active);
  }

  @override
  Stream<List<HudQueueItemEntity>> watchActive(DateTime day) {
    late final StreamController<List<HudQueueItemEntity>> controller;
    controller = StreamController<List<HudQueueItemEntity>>(
      onListen: () {
        _listener = controller.add;
        _emit();
      },
      onCancel: () => _listener = null,
    );
    return controller.stream;
  }

  @override
  Future<Result<void>> raise(SystemAction action, DateTime day) async {
    final existingId = _rows.entries.firstWhereOrNull((e) => e.value.action == action)?.key;
    _rows[existingId ?? _nextId++] = (action: action, day: day, dismissed: false);
    _emit();
    return const Result.success(null);
  }

  @override
  Future<Result<void>> raiseIfNew(SystemAction action, DateTime day) async {
    final exists = _rows.values.any((v) => v.action == action);
    if (!exists) {
      _rows[_nextId++] = (action: action, day: day, dismissed: false);
      _emit();
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> dismiss(int id) async {
    final row = _rows[id];
    if (row != null) _rows[id] = (action: row.action, day: row.day, dismissed: true);
    _emit();
    return const Result.success(null);
  }

  @override
  Future<Result<void>> purgeStale(DateTime today) async {
    _rows.removeWhere((_, v) => v.day != today);
    _emit();
    return const Result.success(null);
  }
}

const drinkButton = WaterQuickButtonEntity(id: 7, volume: 150, label: 'tea', icon: 0);

/// Lets the stream subscriptions started by subscribe() deliver their first
/// (synchronous) values before the next act step runs.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  setUpAll(() {
    registerFallbackValue(NotificationType.waterReminder);
    registerFallbackValue(DayType.weekday);
    registerFallbackValue(const WaterSettingsEntity());
    registerFallbackValue(SystemAction.toilet);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      NotificationDraft(
        type: NotificationType.waterReminder,
        scheduledAt: DateTime(2026),
        title: '',
        body: '',
      ),
    );
  });

  late _MockWaterRepository water;
  late _FakeHudQueueRepository hudQueue;
  late _MockLogWater logWater;
  late _MockPlanReminders planReminders;
  late _MockScheduler scheduler;

  void stubStreams({
    WaterSettingsEntity settings = const WaterSettingsEntity(),
    int currentMl = 0,
    DayScheduleTimesEntity scheduleTimes = const DayScheduleTimesEntity(),
  }) {
    when(() => water.watchDrankToday(any())).thenAnswer((_) => Stream.value(currentMl));
    when(() => water.watchSettings()).thenAnswer((_) => Stream.value(settings));
    when(() => water.watchQuickButtons()).thenAnswer((_) => Stream.value(const [drinkButton]));
    when(
      () => water.ensureDailyGoal(any()),
    ).thenAnswer((_) async => const Result.success(2000));
    when(
      () => water.dayScheduleTimes(any()),
    ).thenAnswer((_) async => Result.success(scheduleTimes));
    when(
      () => water.currentSettings(),
    ).thenAnswer((_) async => Result.success(settings));
  }

  setUp(() {
    water = _MockWaterRepository();
    hudQueue = _FakeHudQueueRepository();
    logWater = _MockLogWater();
    planReminders = _MockPlanReminders();
    scheduler = _MockScheduler();
    stubStreams();
    when(() => logWater(any())).thenAnswer((_) async => const Result.success(null));
    when(
      () => planReminders(
        settings: any(named: 'settings'),
        now: any(named: 'now'),
      ),
    ).thenReturn(const WaterReminderPlan.none());
    when(
      () => scheduler.schedule(any()),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => scheduler.cancelByType(any()),
    ).thenAnswer((_) async => const Result.success(null));
  });

  HudCubit build() => HudCubit(water, hudQueue, logWater, planReminders, scheduler);

  blocTest<HudCubit, HudState>(
    "subscribe loads today's consumption against the fixed daily goal",
    build: build,
    act: (cubit) => cubit.subscribe(),
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final state = cubit.state as HudLoaded;
      expect(state.goalMl, 2000);
      expect(state.currentMl, 0);
      expect(state.contextQueue, isEmpty);
      expect(state.glassBlinking, isFalse);
    },
  );

  blocTest<HudCubit, HudState>(
    'logWater delegates to LogWaterUseCase',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      await cubit.logWater(200);
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      verify(() => logWater(200)).called(1);
    },
  );

  blocTest<HudCubit, HudState>(
    'logDrink resolves the quick button volume',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      await cubit.logDrink(drinkButton.id);
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      verify(() => logWater(drinkButton.volume)).called(1);
    },
  );

  blocTest<HudCubit, HudState>(
    'interval mode replans the water reminder after a log',
    build: build,
    setUp: () {
      when(
        () => planReminders(
          settings: any(named: 'settings'),
          now: any(named: 'now'),
        ),
      ).thenReturn(WaterReminderPlan.single(DateTime(2026, 7, 18, 12)));
    },
    act: (cubit) async {
      stubStreams();
      await cubit.subscribe();
      await settle();
      await cubit.logWater(200);
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      verify(() => scheduler.cancelByType(NotificationType.waterReminder)).called(1);
      verify(() => scheduler.schedule(any())).called(1);
    },
  );

  blocTest<HudCubit, HudState>(
    'onPomodoroStateChanged(isActive: true) blinks the glass',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      cubit.onPomodoroStateChanged(isActive: true);
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      expect((cubit.state as HudLoaded).glassBlinking, isTrue);
    },
  );

  blocTest<HudCubit, HudState>(
    'logging water with showToiletOnWater raises toilet in the queue',
    build: build,
    act: (cubit) async {
      stubStreams(settings: const WaterSettingsEntity(showToiletOnWater: true));
      await cubit.subscribe();
      await settle();
      await cubit.logWater(200);
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final queue = (cubit.state as HudLoaded).contextQueue;
      expect(queue.map((i) => i.action), contains(SystemAction.toilet));
    },
  );

  blocTest<HudCubit, HudState>(
    'onPomodoroBreakStarted raises the toilet suggestion when showToiletOnBreak is set',
    build: build,
    act: (cubit) async {
      stubStreams(settings: const WaterSettingsEntity(showToiletOnBreak: true));
      await cubit.subscribe();
      await settle();
      cubit.onPomodoroBreakStarted();
      await settle();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final queue = (cubit.state as HudLoaded).contextQueue;
      expect(queue.map((i) => i.action), contains(SystemAction.toilet));
    },
  );

  blocTest<HudCubit, HudState>(
    'onQueueItemTapped(toilet) dismisses it from the queue and cancels the reminder',
    build: build,
    act: (cubit) async {
      stubStreams(settings: const WaterSettingsEntity(showToiletOnBreak: true));
      await cubit.subscribe();
      await settle();
      cubit.onPomodoroBreakStarted();
      await settle();
      final id = (cubit.state as HudLoaded).contextQueue.single.id;
      cubit.onQueueItemTapped(id, SystemAction.toilet);
      await settle();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      expect((cubit.state as HudLoaded).contextQueue, isEmpty);
      verify(() => scheduler.cancelByType(NotificationType.toiletReminder)).called(1);
    },
  );

  blocTest<HudCubit, HudState>(
    'dismissQueueItem removes an item without starting anything',
    build: build,
    act: (cubit) async {
      stubStreams(settings: const WaterSettingsEntity(showToiletOnBreak: true));
      await cubit.subscribe();
      await settle();
      cubit.onPomodoroBreakStarted();
      await settle();
      final id = (cubit.state as HudLoaded).contextQueue.single.id;
      cubit.dismissQueueItem(id);
      await settle();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      expect((cubit.state as HudLoaded).contextQueue, isEmpty);
    },
  );

  blocTest<HudCubit, HudState>(
    'starting an activity does not, by itself, raise anything in the queue',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      // Simulates a manual start from the tracker grid: no HudCubit method
      // exists for "an activity started running" — the queue only reacts to
      // schedule time and the toilet triggers.
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      expect((cubit.state as HudLoaded).contextQueue, isEmpty);
    },
  );

  blocTest<HudCubit, HudState>(
    'a schedule event whose time already passed today raises its action',
    build: build,
    act: (cubit) async {
      final now = DateTime.now();
      final past = (now.hour * 60 + now.minute).clamp(1, 1439) - 1;
      stubStreams(
        scheduleTimes: DayScheduleTimesEntity(systemActionTimes: [(SystemAction.meal, past)]),
      );
      await cubit.subscribe();
      await settle();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final queue = (cubit.state as HudLoaded).contextQueue;
      expect(queue.map((i) => i.action), contains(SystemAction.meal));
    },
  );

  blocTest<HudCubit, HudState>(
    'dismissing a schedule-triggered item keeps it gone across a simulated app restart',
    build: build,
    act: (cubit) async {
      final now = DateTime.now();
      final past = (now.hour * 60 + now.minute).clamp(1, 1439) - 1;
      stubStreams(
        scheduleTimes: DayScheduleTimesEntity(systemActionTimes: [(SystemAction.meal, past)]),
      );
      await cubit.subscribe();
      await settle();
      final id = (cubit.state as HudLoaded).contextQueue.single.id;
      cubit.dismissQueueItem(id);
      await settle();

      // A restart recreates HudCubit (fresh in-memory state) but reuses the
      // same persistent hudQueue — this is what previously revived the item.
      final restarted = build();
      await restarted.subscribe();
      await settle();
      expect((restarted.state as HudLoaded).contextQueue, isEmpty);
      await restarted.close();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      expect((cubit.state as HudLoaded).contextQueue, isEmpty);
    },
  );

  blocTest<HudCubit, HudState>(
    'the queue is sorted by SystemAction priority, highest first',
    build: build,
    act: (cubit) async {
      await cubit.subscribe();
      await settle();
      await hudQueue.raise(SystemAction.sleep, DateTime.utc(2026));
      await hudQueue.raise(SystemAction.toilet, DateTime.utc(2026));
      await hudQueue.raise(SystemAction.sport, DateTime.utc(2026));
      await settle();
    },
    wait: const Duration(milliseconds: 20),
    verify: (cubit) {
      final queue = (cubit.state as HudLoaded).contextQueue;
      expect(queue.map((i) => i.action).toList(), [
        SystemAction.toilet,
        SystemAction.sport,
        SystemAction.sleep,
      ]);
    },
  );
}
