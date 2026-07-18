# Data Model — TimeFocus MVP

Схема Drift (SQLite), 14 таблиц. Полные объявления колонок — в PRD, раздел «Ключевые таблицы»;
здесь — сущности, связи, правила валидации и переходы состояний. В БД все enum-ы хранятся как
`int` (`fromIndex(int)`), даты — `DateTime`; «дата дня» нормализуется до полуночи UTC.

## Диаграмма связей

```text
ActionNames 1─* ActionRunnings          (actionNameId, cascade)
ActionNames 1─* ActionHistories         (actionNameId, cascade)
ActionNames 1─* PomodoroSessions        (actionNameId, noAction, nullable)
ActionNames 1─* ScheduleEvents.actionId (setNull, nullable)
ActionNames 1─1 ActionNames.breakActionId (self-ref, noAction, nullable)
ActionNames 1─* ActionNames.groupId       (self-ref: группа → активности)
ActionHistories 1─* ActionHistoryIntervals (cascade)
ActionHistories 1─* ActionRunnings        (actionHistoryId, noAction)
ActionHistories 1─* PomodoroSessions      (actionHistoryId, noAction, nullable)
PomodoroSettings 1─* PomodoroSessions     (settingsId — снимок настроек)
WaterSettings (singleton id=1)   WaterReminderTimes *  WaterQuickButtons *
WaterLogs *                      DailyWaterGoals (уникальна по date)
UserSettings (singleton id=1)    Notifications *
```

## Сущности

### ActionNames — справочник активностей

Ключевые поля: `name`, `color` (ARGB), `icon` (FontAwesome id), `isGroup`, `groupId`,
`sortOrder`, `mode` (ActionMode), `pomodoroType?` (null = Помодоро выключен),
`breakActionId?`, `pauseOthers`, `defaultDurationSec?`, `isSystem`, `hudPriority?`
(1=сон … 4=туалет), `archived`.

Валидация:
- `name` непустое; `mode == breakFor` ⇒ `pomodoroType == null`.
- `breakActionId` может указывать только на активность с `mode == breakFor`; допускается
  общий перерыв для нескольких Помодоро-активностей.
- `isSystem == true` ⇒ запрет удаления (только переименование/настройка/archived для
  скрытия из сетки); `isGroup == true` ⇒ `mode == nothing`, без Помодоро-полей.
- Удаление пользовательской активности: история сохраняется, `ScheduleEvents.actionId → null`
  (setNull), у ссылающихся `breakActionId` сбрасывается в null (edge case спеки).

Seed (12 системных): Работа (pomodoro), Перерыв (breakFor), Отдых, Сон (мьют),
Туалет (pauseOthers, 180 c), Приём пищи (pauseOthers, 1200 c), Спорт (pauseOthers, 1800 c),
Разминка (pauseOthers, 300 c), Прогулка, Медитация (мьют), Молитва (мьют),
Лекарства (120 c). hudPriority: Туалет=4, Еда=3, Спорт=2, Сон=1.

### ActionRunnings — текущее выполнение

`actionNameId`, `actionHistoryId`, `status` (ActionStatus), `startedAt`, `pausedAt?`,
`accumulatedSec`, `pausedBySystem` (bool, default false — активность приостановлена
автоматически pauseOthers-активностью; переживает перезапуск приложения, используется
для автовозобновления по FR-010a).

Инвариант времени: `elapsed = accumulatedSec + (status == active ? now − startedAt : 0)`.

Переходы состояний:
```text
(старт из сетки) → active
active --пауза--> pause    : accumulatedSec += now − startedAt; pausedAt = now
pause  --старт--> active   : startedAt = now
active|pause --стоп--> stop: запись интервала в ActionHistoryIntervals, строка удаляется
```
- Стоп/пауза закрывает текущий интервал `[startedAt(последний), now]` в
  `ActionHistoryIntervals`; возобновление открывает новый.
- Пауза Помодоро-активности дополнительно: PomodoroSession → interrupted (clarification).
- Сортировка UI: active по `startedAt` desc, затем pause по `pausedAt` desc.

### ActionHistories + ActionHistoryIntervals — история

`ActionHistories`: `actionNameId`, `date` (= дата СТАРТА сессии, полночь UTC; интервалы через
полночь не разрезаются — clarification), `comment?`. Одна запись = одна активность в один день.

`ActionHistoryIntervals`: `actionHistoryId`, `startedAt`, `finishedAt`.

Валидация редактирования: `finishedAt >= startedAt` (жёстко); пересечение с другим интервалом
той же активности — предупреждение, сохранение разрешено (clarification). Удаление сессии
каскадно удаляет интервалы.

### PomodoroSettings — настройки (версионируемые)

`shortWorkTime=900`, `normalWorkTime=1500`, `longWorkTime=2700`, `shortBreakTime=300`,
`longBreakTime=900`, `cyclesBeforeLongBreak=4` (3–5), `escalateIntervals`,
`afterAction` (PomodoroAfterAction), `soundEnabled`, `vibrationEnabled`,
`notificationEnabled`, `createdAt`.

Каждое изменение настроек = новая строка (история); сессии ссылаются на снимок → прошлая
статистика не искажается (US7 сценарий 4).

### PomodoroSessions — интервалы Помодоро

`actionNameId?`, `actionHistoryId?`, `settingsId`, `type` (PomodoroType), `plannedTime`,
`actualTime`, `startTime`, `endTime?`, `status` (PomodoroStatus), `cycleNumber` (1..N).

Переходы:
```text
active → completed    : только системный PomodoroWorkIntervalFinished
active → interrupted  : pauseOthers-активность | другой pomodoro | ручной breakFor | пауза активности
active → skipped      : кнопка «Пропустить»
```
`cycleNumber == cyclesBeforeLongBreak` ⇒ следующий перерыв длинный, счётчик сбрасывается.

### ScheduleEvents — расписание дня

`type` (ScheduleEventType: wakeUp/meal/work/sport/sleep/custom), `mealSubtype?` (MealSlot,
только при type==meal), `timeMinutes` (0–1439), `durationMinutes` (default 30), `isStrictly`,
`warningMinutes?` (только strict), `actionId?`, `isEnabled`, `sortOrder`.

Наборы будни/выходные: реализуются полем-признаком или дублированием набора — решение на
уровне tasks (расширение таблицы PRD полем `dayType` int: 0=будни, 1=выходные).
Валидация: `timeMinutes` уникально в рамках (type, dayType) не требуется; wakeUp и sleep —
по одному на набор.

### Вода

- `WaterSettings` (singleton id=1): `dailyWaterGoal`, `weightMode`, `weightKg`, `extraLoad`,
  `reminderMode` (WaterReminderMode), `reminderInterval`, `lastDrankAt?`, `remindersEnabled`,
  `showToiletOnWater`, `showToiletOnBreak`.
- `WaterReminderTimes`: `timeMinutes` — только для scheduled-режима, иначе пуста.
- `WaterQuickButtons`: `volume`, `label` ('water'|'tea'|'coffee'|'milk'|'bottle' — ключ
  локализации), `icon`, `sortOrder`, `isActive`. Seed: вода 200, чай 150, кофе 100,
  молоко 200, бутылка 500.
- `WaterLogs`: `volume`, `createdAt`.
- `DailyWaterGoals`: `date` (uniq), `goalVolume` — фиксация нормы дня при первом логе/старте
  дня; статистика прошлых дней считается по этой норме.

Расчёт цели: `weightMode ? f(weightKg) + extraLoad : dailyWaterGoal + extraLoad`
(формула по весу — константа мл/кг в AppConstants, уточняется в tasks).
Норма к моменту t: линейная интерполяция от wakeUp до sleep из расписания.

### Notifications — зеркало планировщика

`id` (= notificationId в flutter_local_notifications), `type` (NotificationType),
`scheduledAt`, `payload` (JSON-строка), `isDelivered`.

Дедупликация (FR-034a): «контекст» = детерминированный ключ, извлекаемый из payload по типу
(pomodoroFinished/breakFinished → actionId; meal*/sleep → scheduleEventId; waterReminder —
без ключа, тип сам по себе уникален). Перед вставкой NotificationRepository удаляет
недоставленное уведомление с тем же (type, ключ).

Payload-контракты — см. [contracts/notifications.md](./contracts/notifications.md).

### UserSettings (singleton id=1)

`name`, `columnCount`/`rowCount` (1–5), `themeMode` (AppThemeMode), `language`
('en'|'uk'|'ru'|'system'), `notificationsEnabled` (глобальный мьют), `onboardingCompleted`,
`timeFormat` (0=h12,1=h24), `isShortTime`, `reminderRequest`, `isReminder`.

## Энумы (shared/enums/, все с fromIndex)

`ActionMode` (nothing/pomodoro/breakFor) · `ActionStatus` (active/pause/stop) ·
`PomodoroType` (short/normal/long) · `PomodoroStatus` (active/completed/interrupted/skipped) ·
`PomodoroAfterAction` (doNothing/autoStartBreak/suggestBreak/repeatSame/autoStartWork) ·
`WaterReminderMode` (interval/scheduled) · `DrinkType` · `NotificationType` (9 значений) ·
`ScheduleEventType` (wakeUp/meal/work/sport/sleep/custom) · `MealSlot`
(breakfast/lunch/dinner/snack) · `HudContextType` (empty/sleep/sport/meal/toilet) ·
`HistoryMode` (intervals/totals/stats) · `HistoryPeriod` (day/week/month/year) ·
`AppThemeMode` (dark/light/system) · `WaterGoalMode` (weight/manual)
