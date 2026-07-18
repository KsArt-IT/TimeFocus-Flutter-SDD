# Контракты Bloc/Cubit и координация

Глобальные (синглтоны в `AppRoot` через MultiBlocProvider): `AppSettingsCubit`, `ActionBloc`,
`PomodoroBloc`, `HudCubit`, `NotificationBloc`. Экранные (scoped): `ScheduleCubit`,
`HistoryCubit`, `SettingsCubit`, `OnboardingCubit`.

Правила: Bloc не импортирует другой Bloc; side-effects только в listener; после `await` —
`if (isClosed) return;`; состояния — Freezed sealed.

## ActionBloc (tracker)

События (трансформеры):
- `ActionsSubscribed` — restartable(); подписка на Stream запущенных активностей + сетки.
- `ActionStarted(actionNameId, {source})` — droppable(); через **StartActionUseCase**.
- `ActionPaused(runningId)` / `ActionResumed(runningId)` / `ActionStopped(runningId)` — droppable().
- `ActionStartConfirmed(actionNameId)` — подтверждение после предупреждения о прерывании.

Состояние: `initial | loading | loaded(running: List<RunningView>, grid: List<ActionView>,
pendingConfirmation: ActionView?, lastTransition: TransitionEffect?) | error(AppFailure)`.

`TransitionEffect` (для RootBlocListener): `pomodoroInterrupted(byAction, interruptedAction)`,
`pomodoroShouldStart(actionNameId, pomodoroType)`, `pomodoroShouldStop(reason)`,
`breakStarted(breakActionId)`.

### StartActionUseCase — единственная точка матрицы переходов

```dart
bool shouldInterruptPomodoro(ActionNameEntity action, {required bool isSystemTransition}) =>
    !isSystemTransition &&
    (action.mode == ActionMode.pomodoro ||
     action.mode == ActionMode.breakFor ||   // ручной запуск перерыва
     action.pauseOthers);
```
- Системный переход (`isSystemTransition == true`, PomodoroWorkIntervalFinished) — НЕ прерывает.
- Запуск второго pomodoro без подтверждения → состояние `pendingConfirmation` (FR-011);
  отказ — ничего не меняется.
- Пауза pomodoro-активности → эффект `pomodoroShouldStop(pausedByUser)` (clarification: interrupted).
- pauseOthers (FR-010a/b): рабочий интервал → interrupted; остальные активные активности —
  на паузу с флагом `pausedBySystem` и автовозобновлением после остановки pauseOthers-активности.
  Исключение: во время перерыва break-активность и цикл не затрагиваются.
- Счётчик цикла: interrupted-интервал не засчитывается, следующий стартует с тем же
  cycleNumber; сброс цикла — только по «Стоп» активности (FR-014).

## PomodoroBloc (pomodoro)

События: `PomodoroStarted(actionNameId, type, historyId)` — droppable();
`PomodoroWorkIntervalFinished(sessionId)` — sequential() (из NotificationBloc/таймера);
`PomodoroInterrupted(reason)`; `PomodoroSkipped`; `PomodoroBreakFinished(sessionId)`;
`PomodoroBreakExtended(minutes)`.

Состояние: `idle | workRunning(session, endsAt, cycle) | breakRunning(session, endsAt,
parentActionId) | readyToResumeWork(parentActionId, nextCycle) | error(AppFailure)`.

Логика: `completed` только из `PomodoroWorkIntervalFinished`; выбор длинного перерыва по
`cycleNumber == cyclesBeforeLongBreak`; `afterAction` определяет авто-переходы (FR-018).

## HudCubit (water)

Методы: `subscribe()`, `logWater(volume)`, `logDrink(quickButtonId)`,
`onPomodoroBreakStarted()`, `onPomodoroStateChanged(isActive)`, `onToiletTapped()`,
`dismissContext()`.

Состояние: `loaded(currentMl, goalMl, expectedByNowMl, context: HudContextType,
contextPulsing: bool, glassBlinking: bool)`.

**HudContextResolver** (чистая функция, domain): входы — флаги туалет-триггеров, слот еды по
времени, события спорт/сон, Помодоро активен; выход — HudContextType по приоритету
Туалет(4) > Еда(3) > Спорт(2) > Сон(1) > пусто. Туалет только при showToiletOnWater/OnBreak.

## NotificationBloc (notifications)

События: `NotificationsInitialized` (cold start details), `NotificationTapped(payload)`,
`ScheduleRecalculated(trigger)` — sequential(); `NotificationActionInvoked(actionId, input)`.

Обязанности: планирование/отмена через NotificationScheduler (см. notifications.md),
пересчёт при: старте приложения, старте/стопе активности, изменении расписания/настроек воды,
питье (interval-режим). Диспетчеризация тапов → deep-link go_router + события Bloc-ов
через RootBlocListener.

## AppSettingsCubit (settings)

Подписан на `UserSettingsRepository.watch()`. Состояние: `(themeMode, locale, timeFormat,
isShortTime, gridSize)`. Методы — сеттеры, пишущие в репозиторий (Stream сам обновит состояние).

## RootBlocListener — таблица координации

| Источник (состояние/эффект) | Приёмник (действие) |
|---|---|
| ActionBloc.lastTransition == pomodoroShouldStart | PomodoroBloc.add(PomodoroStarted…) |
| ActionBloc.lastTransition == pomodoroShouldStop | PomodoroBloc.add(PomodoroInterrupted…) |
| ActionBloc.lastTransition == pomodoroInterrupted | toastification: «Помодоро прерван…» |
| ActionBloc.lastTransition == breakStarted | HudCubit.onPomodoroBreakStarted() |
| PomodoroBloc.readyToResumeWork(id) | ActionBloc.add(ActionStarted(id, source: system)) |
| PomodoroBloc.workRunning/idle | HudCubit.onPomodoroStateChanged(...), NotificationBloc.add(ScheduleRecalculated) |
| PomodoroBloc.breakRunning | HudCubit.onPomodoroBreakStarted() |
| NotificationBloc.tapDispatched(intent) | соответствующий Bloc.add(...) + router.go(deepLink) |

## Экранные кубиты

- `ScheduleCubit`: `loaded(timeline: List<TimelineItem>, dayType)`; CRUD событий; таймлайн =
  merge(план, интервалы истории, точки воды, активные напоминания).
- `HistoryCubit`: `loaded(mode, period, anchor DateTime, header: HeaderStats, items)`;
  header.totalTime = все активности кроме «Сон» (clarification); редактирование через
  usecases с предупреждением о пересечении.
- `SettingsCubit` — экраны настроек (активности, помодоро, вода, напоминания).
- `OnboardingCubit`: шаги, skip, запись onboardingCompleted.
