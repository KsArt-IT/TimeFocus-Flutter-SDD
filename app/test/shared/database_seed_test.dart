import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/action_mode.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('onCreate seeds 12 system activities with hud priorities', () async {
    final actions = await db.select(db.actionNames).get();
    expect(actions.length, 12);
    expect(actions.every((a) => a.isSystem), isTrue);
    expect(actions.map((a) => a.name).toSet(), SystemActionKeys.all.toSet());

    ActionNameModel byName(String name) => actions.singleWhere((a) => a.name == name);
    expect(byName(SystemActionKeys.toilet).hudPriority, 4);
    expect(byName(SystemActionKeys.meal).hudPriority, 3);
    expect(byName(SystemActionKeys.sport).hudPriority, 2);
    expect(byName(SystemActionKeys.sleep).hudPriority, 1);

    final work = byName(SystemActionKeys.work);
    final breakAction = byName(SystemActionKeys.breakKey);
    expect(work.mode, ActionMode.pomodoro.index);
    expect(work.breakActionId, breakAction.id);
    expect(breakAction.mode, ActionMode.breakFor.index);

    expect(byName(SystemActionKeys.toilet).pauseOthers, isTrue);
    expect(byName(SystemActionKeys.meal).pauseOthers, isTrue);
    expect(byName(SystemActionKeys.toilet).defaultDurationSec, 180);
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
    expect(weekday.length, 5);
    expect(weekend.length, 5);
    // wakeUp and sleep — exactly one per set.
    expect(weekday.where((e) => e.type == 0).length, 1);
    expect(weekday.where((e) => e.type == 4).length, 1);
    expect(weekend.where((e) => e.type == 0).length, 1);
    expect(weekend.where((e) => e.type == 4).length, 1);
  });
}
