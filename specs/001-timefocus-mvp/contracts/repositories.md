# Контракты репозиториев (domain-слой)

Все — `abstract interface class` в `features/<name>/domain/repositories/`, возвращают
`Result<T>` (или `Stream<T>` для watch-методов; ошибки Stream-ов мапятся в состояния error
на уровне Cubit). Реализации в `data/repositories/` поверх DAO из `shared/database/`.

## tracker

```dart
abstract interface class ActionNameRepository {
  Stream<List<ActionNameEntity>> watchGrid({int? groupId});     // archived=false, по sortOrder
  Future<Result<ActionNameEntity>> getById(int id);
  Future<Result<int>> create(ActionNameEntity e);
  Future<Result<void>> update(ActionNameEntity e);
  Future<Result<void>> archive(int id);
  Future<Result<void>> delete(int id);   // isSystem → ValidationFailure; чистит ссылки
}

abstract interface class ActionRunningRepository {
  Stream<List<RunningWithNameEntity>> watchRunning();           // сорт. active/pause
  Future<Result<int>> start({required int actionNameId, required DateTime now});
      // находит/создаёт ActionHistory на дату старта, создаёт running
  Future<Result<void>> pause(int runningId, DateTime now);      // закрывает интервал
  Future<Result<void>> resume(int runningId, DateTime now);
  Future<Result<void>> stop(int runningId, DateTime now);       // закрывает интервал, удаляет running
  Future<Result<int>> todayTotalSec(int actionNameId, DateTime day);
}
```

## pomodoro

```dart
abstract interface class PomodoroRepository {
  Future<Result<PomodoroSessionEntity>> startSession({required int actionNameId,
      required int historyId, required PomodoroType type, required int cycleNumber});
  Future<Result<void>> finish(int sessionId, PomodoroStatus status, DateTime now);
  Future<Result<PomodoroSessionEntity?>> activeSession();
  Future<Result<(int completed, int interrupted)>> countByPeriod(DateTime from, DateTime to);
}

abstract interface class PomodoroSettingsRepository {
  Future<Result<PomodoroSettingsEntity>> current();       // последняя строка
  Future<Result<int>> saveNewVersion(PomodoroSettingsEntity e); // всегда insert
  Stream<PomodoroSettingsEntity> watch();
}
```

## water

```dart
abstract interface class WaterRepository {
  Stream<WaterHudEntity> watchToday();       // выпито, цель дня, норма к текущему моменту
  Future<Result<void>> log(int volume, DateTime now);   // + lastDrankAt, + DailyWaterGoal при первом логе
  Stream<List<WaterQuickButtonEntity>> watchQuickButtons();
  Future<Result<void>> saveQuickButton(WaterQuickButtonEntity e);
  Future<Result<WaterSettingsEntity>> settings();
  Future<Result<void>> saveSettings(WaterSettingsEntity e);
  Stream<WaterSettingsEntity> watchSettings();
  Future<Result<List<TimeOfDayMinutes>>> reminderTimes();
  Future<Result<void>> saveReminderTimes(List<TimeOfDayMinutes> times);
  Future<Result<(int drank, int goal)>> totalByPeriod(DateTime from, DateTime to);
}
```

## schedule

```dart
abstract interface class ScheduleRepository {
  Stream<List<ScheduleEventEntity>> watchDay(DayType dayType);
  Future<Result<int>> create(ScheduleEventEntity e);
  Future<Result<void>> update(ScheduleEventEntity e);
  Future<Result<void>> delete(int id);
  Future<Result<List<ScheduleEventEntity>>> strictEventsAfter(DateTime now); // для warning
}
// Точка расширения Фазы 2 (FR-033):
abstract interface class CalendarDataSource {
  Future<Result<List<ExternalEventEntity>>> eventsFor(DateTime day);
}
```

## history

```dart
abstract interface class HistoryRepository {
  Future<Result<HistoryHeaderEntity>> header(DateTime from, DateTime to);
      // totalSec: SUM всех интервалов КРОМЕ активности «Сон» (clarification)
  Stream<List<HistoryIntervalEntity>> watchIntervals(DateTime from, DateTime to);
  Stream<List<HistoryTotalEntity>> watchTotals(DateTime from, DateTime to);
  Future<Result<HistorySessionEntity>> session(int historyId);
  Future<Result<void>> updateSession({required int historyId, int? newActionNameId,
      String? comment});
  Future<Result<OverlapCheck>> saveInterval(HistoryIntervalEdit e);
      // finishedAt < startedAt → ValidationFailure; overlap → OverlapCheck.warning (сохранено)
  Future<Result<void>> deleteInterval(int intervalId);
  Future<Result<void>> deleteSession(int historyId);  // cascade
}
```

## settings / notifications / onboarding

```dart
abstract interface class UserSettingsRepository {
  Stream<UserSettingsEntity> watch();
  Future<Result<UserSettingsEntity>> get();
  Future<Result<void>> save(UserSettingsEntity e);   // singleton id=1, upsert
}

abstract interface class NotificationRepository {   // зеркало планировщика
  Future<Result<int>> insert(NotificationDraft d);
  Future<Result<void>> delete(int id);
  Future<Result<void>> deleteByType(NotificationType t);
  Future<Result<List<NotificationEntity>>> pending(DateTime after);
  Future<Result<void>> markDelivered(int id);
}
```

## Ключевые UseCase-ы (domain/usecases)

| UseCase | Фича | Ответственность |
|---|---|---|
| StartActionUseCase | tracker | матрица переходов, shouldInterruptPomodoro, pendingConfirmation |
| StopActionUseCase / PauseActionUseCase | tracker | закрытие интервалов + эффект для Помодоро |
| FinishPomodoroIntervalUseCase | pomodoro | completed, выбор short/long перерыва, afterAction |
| CheckStrictEventsUseCase | pomodoro/schedule | предупреждения mealStrictWarning при старте |
| LogWaterUseCase | water | лог + DailyWaterGoal + interval-перепланирование + туалет-триггер |
| ResolveHudContextUseCase | water/hud | чистый резолвер приоритета иконки |
| PlanDayNotificationsUseCase | notifications | scheduled-вода, еда, сон на день |
| HandleNotificationTapUseCase | notifications | payload → intent (cold/warm) |
```
