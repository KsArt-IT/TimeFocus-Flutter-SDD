import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('onCreate seeds 12 system activities', () async {
    final actions = await db.select(db.actionNames).get();
    expect(actions.length, 12);
    expect(actions.every((a) => a.isSystem), isTrue);
    expect(actions.map((a) => a.name).toSet(), SystemAction.values.map((e) => e.name).toSet());

    ActionNameModel byName(SystemAction action) => actions.singleWhere(
      (a) => a.name == action.name,
    );

    final work = byName(SystemAction.work);
    final breakAction = byName(SystemAction.breakFor);
    expect(work.mode, ActionMode.pomodoro.index);
    expect(work.breakActionId, breakAction.id);
    expect(breakAction.mode, ActionMode.breakFor.index);

    expect(byName(SystemAction.toilet).pauseOthers, isTrue);
    expect(byName(SystemAction.meal).pauseOthers, isTrue);
    expect(byName(SystemAction.toilet).defaultDurationSec, 180);
  });

  test('onCreate seeds 5 drink quick buttons', () async {
    final drinks = await db.select(db.waterQuickButtons).get();
    expect(drinks.length, 5);
    expect(drinks.map((d) => d.label).toList(), [
      'water',
      'tea',
      'coffee',
      'milk',
      'bottle',
    ]);
    expect(drinks.singleWhere((d) => d.label == 'bottle').volume, 500);
  });

  test('onCreate seeds singleton settings rows', () async {
    final user = await db.settingsDao.get();
    expect(user.id, 1);
    expect(user.onboardingCompleted, isFalse);
    expect(user.columnCount, 4);
    expect(user.rowCount, 5);

    final water = await db.waterDao.getSettings();
    expect(water.id, 1);
    expect(water.dailyWaterGoal, 2000);

    final pomodoro = await db.pomodoroDao.currentSettings();
    expect(pomodoro.normalWorkTime, 1500);
    expect(pomodoro.cyclesBeforeLongBreak, 4);
  });

  test('onCreate seeds weekday and weekend schedules', () async {
    final weekday = await db.scheduleDao.eventsForDay(0);
    final weekend = await db.scheduleDao.eventsForDay(1);
    expect(weekday.length, 6);
    expect(weekend.length, 6);
    // wakeUp, warmup and sleep — exactly one per set.
    expect(weekday.where((e) => e.type == ScheduleEventType.wakeUp.name).length, 1);
    expect(weekday.where((e) => e.type == ScheduleEventType.warmup.name).length, 1);
    expect(weekday.where((e) => e.type == ScheduleEventType.sleep.name).length, 1);
    expect(weekend.where((e) => e.type == ScheduleEventType.wakeUp.name).length, 1);
    expect(weekend.where((e) => e.type == ScheduleEventType.warmup.name).length, 1);
    expect(weekend.where((e) => e.type == ScheduleEventType.sleep.name).length, 1);
  });
}
