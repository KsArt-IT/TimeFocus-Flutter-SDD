# Контракт уведомлений

Все уведомления локальные, планируются заранее (`zonedSchedule`, `tz.TZDateTime`,
exactAllowWhileIdle с fallback). Каждое зеркалируется в таблице `notifications`
(id = notificationId). Payload — JSON-строка, самодостаточная для cold start.

## Типы, триггеры, правила

| NotificationType | Триггер | Прерывает Помодоро | Откладывается |
|---|---|---|---|
| pomodoroFinished (0) | конец рабочего интервала | нет (штатное завершение) | нет |
| breakFinished (1) | конец перерыва | нет | нет |
| mealFlexible (2) | время гибкой еды прошло | нет | да — до конца Помодоро |
| mealStrict (3) | точное время строгого события | да — принудительно | нет |
| mealStrictWarning (4) | Помодоро не успевает до строгого события | нет | нет |
| waterReminder (5) | интервал/расписание воды | нет | да — до ближайшего перерыва |
| toiletReminder (6) | старт перерыва / питьё (по флагам) | нет | нет |
| sleepReminder (7) | за 30 мин до сна | нет | да — до конца Помодоро |
| extendBreak (8) | кнопка в breakFinished | нет | нет |

Строгое событие: Помодоро прерывается системой, уведомление отправляется; связанная
активность запускается ТОЛЬКО по тапу (clarification — авто-старта нет).

Мьют: активные Сон/Медитация/Молитва или `UserSettings.notificationsEnabled == false` —
уведомления не показываются.

Отложенные (Помодоро/мьют): после окончания доставляются ВСЕ накопленные, по очереди
(FR-034a). В планировщике не более одного недоставленного уведомления одного типа с
одинаковым контекстом — новое заменяет старое. Ключ контекста по типу: actionId
(pomodoroFinished/breakFinished/extendBreak), scheduleEventId (meal*/sleepReminder),
только тип (waterReminder/toiletReminder). Тап по устаревшему уведомлению — открытие
приложения без действия и без сбоя (FR-035). Запланированные уведомления переживают reboot
(механизм плагина/ОС) + `rescheduleAll()` при каждом старте приложения (FR-035a).

## Payload-схемы (JSON)

```json
pomodoroFinished:   {"actionId": int, "breakActionId": int|null}
breakFinished:      {"parentActionId": int, "pomodoroCount": int}
mealFlexible:       {"scheduleEventId": int, "targetActionId": int|null}
mealStrict:         {"scheduleEventId": int, "targetActionId": int|null}
mealStrictWarning:  {"scheduleEventId": int, "minutesUntilEvent": int, "currentPomodoroEndAt": iso8601}
waterReminder:      {"currentMl": int, "goalMl": int, "recommendedGlasses": int}
toiletReminder:     {}
sleepReminder:      {"sleepTimeMinutes": int}
extendBreak:        {"breakActionId": int, "extraMinutes": int}
```

## Обработка тапа (warm и cold start — один путь)

```text
tap → NotificationBloc.NotificationTapped(payloadJson)
  → parse type + payload → intent:
    pomodoroFinished  → deep-link /tracker + (afterAction: старт breakActionId | предложение)
    breakFinished     → /tracker + ActionStarted(parentActionId, source: system)
    mealFlexible/Strict → /tracker + ActionStarted(targetActionId) по подтверждению тапом
    waterReminder     → /tracker (HUD в фокусе)
    sleepReminder     → /tracker
    extendBreak       → продление перерыва на extraMinutes без открытия экрана (action button)
Cold start: getNotificationAppLaunchDetails() → тот же NotificationTapped после инициализации AppRoot.
```

## NotificationScheduler — единственная точка планирования

Интерфейс (core/domain notifications):
```dart
abstract interface class NotificationScheduler {
  Future<Result<void>> schedule(NotificationDraft draft); // пишет в БД + zonedSchedule
  Future<Result<void>> cancel(int id);
  Future<Result<void>> cancelByType(NotificationType type);
  Future<Result<void>> rescheduleAll();   // cold start / смена настроек
}
```

Правила пересчёта (`rescheduleAll` / точечные):
- Старт Помодоро → schedule(pomodoroFinished, endsAt) + пересчёт mealStrictWarning всех
  строгих событий дня (`eventTime − now < pomodoroDuration` → немедленное предупреждение).
- Пауза/прерывание Помодоро → cancel(pomodoroFinished этой сессии).
- Питьё в interval-режиме → cancelByType(waterReminder) + schedule(lastDrankAt + N мин).
- Старт дня/смена расписания в scheduled-режиме → все waterReminder дня разом; окно ±15 мин
  от еды — пропуск.
- Разрешения: SDK 33+ POST_NOTIFICATIONS, SDK 31+ SCHEDULE_EXACT_ALARM; отказ → напоминания
  отключены, трекинг работает (FR-036).

## Deep-links (go_router)

В shell: `/tracker`, `/schedule`, `/history`. Вне shell: `/settings/*`, `/onboarding`,
`/action/edit/:id?`, `/interval/edit/:id`. Уведомления ведут на `/tracker`
(+ параметры intent), обязательна работа из terminated-состояния.
