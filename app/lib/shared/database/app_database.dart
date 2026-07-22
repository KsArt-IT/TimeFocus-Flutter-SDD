import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/shared/database/daos/action_dao.dart';
import 'package:timefocus/shared/database/daos/history_dao.dart';
import 'package:timefocus/shared/database/daos/hud_queue_dao.dart';
import 'package:timefocus/shared/database/daos/notification_dao.dart';
import 'package:timefocus/shared/database/daos/pomodoro_dao.dart';
import 'package:timefocus/shared/database/daos/running_dao.dart';
import 'package:timefocus/shared/database/daos/schedule_dao.dart';
import 'package:timefocus/shared/database/daos/settings_dao.dart';
import 'package:timefocus/shared/database/daos/water_dao.dart';
import 'package:timefocus/shared/database/tables/action_tables.dart';
import 'package:timefocus/shared/database/tables/app_tables.dart';
import 'package:timefocus/shared/database/tables/hud_tables.dart';
import 'package:timefocus/shared/database/tables/pomodoro_tables.dart';
import 'package:timefocus/shared/database/tables/schedule_tables.dart';
import 'package:timefocus/shared/database/tables/water_tables.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/meal_slot.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';

part 'app_database.g.dart';

@singleton
@DriftDatabase(
  tables: [
    ActionNames,
    ActionRunnings,
    ActionHistories,
    ActionHistoryIntervals,
    PomodoroSettings,
    PomodoroSessions,
    WaterSettings,
    WaterReminderTimes,
    WaterQuickButtons,
    WaterLogs,
    DailyWaterGoals,
    HudQueueItems,
    ScheduleEvents,
    Notifications,
    UserSettings,
  ],
  daos: [
    ActionDao,
    RunningDao,
    HistoryDao,
    PomodoroDao,
    WaterDao,
    HudQueueDao,
    ScheduleDao,
    NotificationDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'timefocus'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seed();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seed() async {
    await transaction(() async {
      final breakId = await into(actionNames).insert(
        ActionNamesCompanion.insert(
          name: SystemAction.breakFor.name,
          color: 0xFF7FB069,
          icon: SystemAction.breakFor.icon.data.codePoint,
          mode: Value(ActionMode.breakFor.index),
          isSystem: const Value(true),
          sortOrder: const Value(1),
        ),
      );
      final seedActions = <ActionNamesCompanion>[
        ActionNamesCompanion.insert(
          name: SystemAction.work.name,
          color: 0xFF4A6FA5,
          icon: SystemAction.work.icon.data.codePoint,
          mode: Value(ActionMode.pomodoro.index),
          pomodoroType: Value(PomodoroType.normal.index),
          breakActionId: Value(breakId),
          isSystem: const Value(true),
          sortOrder: const Value(0),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.rest.name,
          color: 0xFF9B8AC4,
          icon: SystemAction.rest.icon.data.codePoint,
          isSystem: const Value(true),
          sortOrder: const Value(2),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.warmup.name,
          color: 0xFFE6A23C,
          icon: SystemAction.warmup.icon.data.codePoint,
          pauseOthers: const Value(true),
          defaultDurationSec: const Value(300),
          isSystem: const Value(true),
          sortOrder: const Value(3),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.toilet.name,
          color: 0xFF8D9CA3,
          icon: SystemAction.toilet.icon.data.codePoint,
          pauseOthers: const Value(true),
          defaultDurationSec: const Value(180),
          isSystem: const Value(true),
          sortOrder: const Value(4),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.meal.name,
          color: 0xFFE0885A,
          icon: SystemAction.meal.icon.data.codePoint,
          pauseOthers: const Value(true),
          defaultDurationSec: const Value(1200),
          isSystem: const Value(true),
          sortOrder: const Value(5),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.sport.name,
          color: 0xFFD1495B,
          icon: SystemAction.sport.icon.data.codePoint,
          pauseOthers: const Value(true),
          defaultDurationSec: const Value(1800),
          isSystem: const Value(true),
          sortOrder: const Value(6),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.walk.name,
          color: 0xFF56A3A6,
          icon: SystemAction.walk.icon.data.codePoint,
          isSystem: const Value(true),
          sortOrder: const Value(7),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.meditation.name,
          color: 0xFF7E57C2,
          icon: SystemAction.meditation.icon.data.codePoint,
          isSystem: const Value(true),
          sortOrder: const Value(8),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.prayer.name,
          color: 0xFFB08968,
          icon: SystemAction.prayer.icon.data.codePoint,
          isSystem: const Value(true),
          sortOrder: const Value(9),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.medicine.name,
          color: 0xFF66BB6A,
          icon: SystemAction.medicine.icon.data.codePoint,
          defaultDurationSec: const Value(120),
          isSystem: const Value(true),
          sortOrder: const Value(10),
        ),
        ActionNamesCompanion.insert(
          name: SystemAction.sleep.name,
          color: 0xFF5C6BC0,
          icon: SystemAction.sleep.icon.data.codePoint,
          isSystem: const Value(true),
          sortOrder: const Value(11),
        ),
      ];
      for (final a in seedActions) {
        await into(actionNames).insert(a);
      }

      const drinks = [
        (label: 'water', volume: 200, icon: 0xe4f4),
        (label: 'tea', volume: 150, icon: 0xf0f4),
        (label: 'coffee', volume: 100, icon: 0xf7b6),
        (label: 'milk', volume: 200, icon: 0xe4f3),
        (label: 'bottle', volume: 500, icon: 0xe4c5),
      ];
      for (final (i, d) in drinks.indexed) {
        await into(waterQuickButtons).insert(
          WaterQuickButtonsCompanion.insert(
            volume: d.volume,
            label: d.label,
            icon: d.icon,
            sortOrder: Value(i),
          ),
        );
      }

      await into(userSettings).insert(const UserSettingsCompanion(id: Value(1)));
      await into(waterSettings).insert(const WaterSettingsCompanion(id: Value(1)));
      await into(pomodoroSettings).insert(
        PomodoroSettingsCompanion.insert(createdAt: DateTime.now()),
      );

      const weekday = 0;
      const weekend = 1;
      const schedule = [
        (day: weekday, type: ScheduleEventType.wakeUp, slot: null, time: 7 * 60),
        (day: weekday, type: ScheduleEventType.warmup, slot: null, time: 7 * 60 + 10),
        (day: weekday, type: ScheduleEventType.meal, slot: MealSlot.breakfast, time: 8 * 60),
        (day: weekday, type: ScheduleEventType.meal, slot: MealSlot.lunch, time: 12 * 60),
        (day: weekday, type: ScheduleEventType.meal, slot: MealSlot.dinner, time: 18 * 60),
        (day: weekday, type: ScheduleEventType.sleep, slot: null, time: 23 * 60),

        (day: weekend, type: ScheduleEventType.wakeUp, slot: null, time: 8 * 60),
        (day: weekend, type: ScheduleEventType.warmup, slot: null, time: 8 * 60 + 10),
        (day: weekend, type: ScheduleEventType.meal, slot: MealSlot.breakfast, time: 9 * 60),
        (day: weekend, type: ScheduleEventType.meal, slot: MealSlot.lunch, time: 13 * 60),
        (day: weekend, type: ScheduleEventType.meal, slot: MealSlot.dinner, time: 18 * 60),
        (day: weekend, type: ScheduleEventType.sleep, slot: null, time: 23 * 60 + 30),
      ];
      for (final (i, e) in schedule.indexed) {
        await into(scheduleEvents).insert(
          ScheduleEventsCompanion.insert(
            type: e.type.name,
            mealSubtype: Value(e.slot?.index),
            timeMinutes: e.time,
            dayType: Value(e.day),
            sortOrder: Value(i),
          ),
        );
      }
    });
  }
}
