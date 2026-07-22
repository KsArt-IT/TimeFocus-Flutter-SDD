import 'package:flutter_test/flutter_test.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/action_status.dart';
import 'package:timefocus/shared/enums/app_theme_mode.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/drink_type.dart';
import 'package:timefocus/shared/enums/history_mode.dart';
import 'package:timefocus/shared/enums/history_period.dart';
import 'package:timefocus/shared/enums/meal_slot.dart';
import 'package:timefocus/shared/enums/notification_type.dart';
import 'package:timefocus/shared/enums/pomodoro_after_action.dart';
import 'package:timefocus/shared/enums/pomodoro_status.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';
import 'package:timefocus/shared/enums/water_goal_mode.dart';
import 'package:timefocus/shared/enums/water_reminder_mode.dart';

void main() {
  group('fromIndex roundtrip', () {
    test('ActionMode', () {
      for (final v in ActionMode.values) {
        expect(ActionMode.fromIndex(v.index), v);
      }
    });
    test('ActionStatus', () {
      for (final v in ActionStatus.values) {
        expect(ActionStatus.fromIndex(v.index), v);
      }
    });
    test('PomodoroType', () {
      for (final v in PomodoroType.values) {
        expect(PomodoroType.fromIndex(v.index), v);
      }
    });
    test('PomodoroStatus', () {
      for (final v in PomodoroStatus.values) {
        expect(PomodoroStatus.fromIndex(v.index), v);
      }
    });
    test('PomodoroAfterAction', () {
      for (final v in PomodoroAfterAction.values) {
        expect(PomodoroAfterAction.fromIndex(v.index), v);
      }
    });
    test('WaterReminderMode', () {
      for (final v in WaterReminderMode.values) {
        expect(WaterReminderMode.fromIndex(v.index), v);
      }
    });
    test('DrinkType', () {
      for (final v in DrinkType.values) {
        expect(DrinkType.fromIndex(v.index), v);
      }
    });
    test('NotificationType', () {
      for (final v in NotificationType.values) {
        expect(NotificationType.fromIndex(v.index), v);
      }
    });
    test('ScheduleEventType', () {
      for (final v in ScheduleEventType.values) {
        expect(ScheduleEventType.fromName(v.name), v);
      }
    });
    test('MealSlot', () {
      for (final v in MealSlot.values) {
        expect(MealSlot.fromIndex(v.index), v);
      }
    });
    test('HistoryMode', () {
      for (final v in HistoryMode.values) {
        expect(HistoryMode.fromIndex(v.index), v);
      }
    });
    test('HistoryPeriod', () {
      for (final v in HistoryPeriod.values) {
        expect(HistoryPeriod.fromIndex(v.index), v);
      }
    });
    test('AppThemeMode', () {
      for (final v in AppThemeMode.values) {
        expect(AppThemeMode.fromIndex(v.index), v);
      }
    });
    test('WaterGoalMode', () {
      for (final v in WaterGoalMode.values) {
        expect(WaterGoalMode.fromIndex(v.index), v);
      }
    });
    test('DayType', () {
      for (final v in DayType.values) {
        expect(DayType.fromIndex(v.index), v);
      }
    });
  });

  group('fromIndex out of range falls back to default', () {
    test('does not throw on invalid index', () {
      expect(ActionMode.fromIndex(99), ActionMode.nothing);
      expect(ActionStatus.fromIndex(-1), ActionStatus.stop);
      expect(NotificationType.fromIndex(99), NotificationType.waterReminder);
      expect(AppThemeMode.fromIndex(99), AppThemeMode.system);
    });
  });

  group('SystemAction HUD priority', () {
    test('medicine > toilet > warmup > meal > sport, work > sleep', () {
      expect(SystemAction.medicine.priority, greaterThan(SystemAction.toilet.priority));
      expect(SystemAction.toilet.priority, greaterThan(SystemAction.warmup.priority));
      expect(SystemAction.warmup.priority, greaterThan(SystemAction.meal.priority));
      expect(SystemAction.meal.priority, greaterThan(SystemAction.sport.priority));
      expect(SystemAction.work.priority, greaterThan(SystemAction.sleep.priority));
    });
  });

  group('DayType.fromDate', () {
    test('weekday and weekend detection', () {
      expect(DayType.fromDate(DateTime(2026, 7, 17)), DayType.weekday); // Friday
      expect(DayType.fromDate(DateTime(2026, 7, 18)), DayType.weekend); // Saturday
      expect(DayType.fromDate(DateTime(2026, 7, 19)), DayType.weekend); // Sunday
      expect(DayType.fromDate(DateTime(2026, 7, 20)), DayType.weekday); // Monday
    });
  });
}
