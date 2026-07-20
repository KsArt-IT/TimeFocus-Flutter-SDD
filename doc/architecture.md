# Архитектура

Краткий обзор. Полные соглашения кодовой базы — в [CLAUDE.md](../CLAUDE.md); полная модель
данных и контракты — в [specs/001-timefocus-mvp/](../specs/001-timefocus-mvp/).

## Слои

Feature First + Clean Architecture. Каждая фича в `app/lib/features/<name>/` содержит три
слоя:

```
data/
├── datasources/   # DAO-обёртки над Drift
├── mappers/       # Model (Drift) ↔ Entity (Freezed, domain)
└── repositories/  # <Name>RepositoryImpl — реализует интерфейс из domain/
domain/
├── entities/      # Freezed, чистый Dart, без импортов Flutter/Drift
├── repositories/  # abstract interface class
└── usecases/      # бизнес-правила (единственное место их определения)
presentation/
├── bloc/ или cubit/   # состояние экрана/фичи
├── pages/             # экраны
└── widgets/           # виджеты фичи
```

Правила, которые не нарушаются:

- `domain/` не знает о Flutter/Drift — только Dart.
- Bloc/Cubit зависит только от абстрактных репозиториев из `domain/`, никогда от DAO напрямую.
- **Bloc не импортирует другой Bloc.** Координация между фичами — только через
  `RootBlocListener` (`app/lib/app/root_bloc_listener.dart`).
- `presentation/` одной фичи не импортирует `presentation/` другой.

## Глобальные Bloc/Cubit

Синглтоны, живут всё время приложения, создаются в `AppRoot` через `MultiBlocProvider`:

| Bloc/Cubit | Фича | Ответственность |
|---|---|---|
| `AppSettingsCubit` | settings | тема + язык, читает Drift `Stream` |
| `ActionBloc` | tracker | старт/пауза/стоп активностей |
| `PomodoroBloc` | pomodoro | Помодоро-сессии и перерывы |
| `HudCubit` | water | полоска воды + контекстная иконка HUD |
| `NotificationBloc` | notifications | планирование и обработка уведомлений |

`RootBlocListener` — единственное место, где Bloc-и реагируют друг на друга, например:

```
PomodoroBloc.readyToResumeWork(id) → ActionBloc.start(id)
PomodoroBloc.breakRunning          → HudCubit.onPomodoroBreakStarted()
ActionBloc.pomodoroInterrupted     → тост «Помодоро прерван …»
```

`AppRoot` также реализует `WidgetsBindingObserver`: при возврате приложения из фона
(`AppLifecycleState.resumed`) повторно инициализирует `NotificationBloc`, который
пересчитывает все запланированные уведомления по актуальному локальному времени — защита от
смены часового пояса/системных часов, пока приложение было свёрнуто.

## Данные

**Drift (SQLite)** — единственное хранилище, offline-first, 14 таблиц
(`app/lib/shared/database/tables/`): активности и их запуски/история/интервалы,
Помодоро-сессии и настройки, вода (логи/настройки/быстрые кнопки/дневные цели/времена
напоминаний), события расписания, уведомления, настройки пользователя.

Таймер не имеет фонового процесса — время всегда пересчитывается как
`now.secondsSince(startedAt) + accumulatedSec` (`core/utils/time_guard.dart`), с защитой от
отрицательного интервала при откате системных часов.

## Ошибки

```
DataSource → (throws) → Repository.safeCall/voidSafeCall (SafeCallMixin) → Result<T>
                                                                              │
                                                          fold(success | failure(AppFailure))
                                                                              │
                                                    Bloc/Cubit emit(state.error(failure))
                                                                              │
                              RootBlocListener → toastification, либо inline-виджет формы
```

`Result<T>` — собственный sealed class (`core/result/result.dart`), никогда не пропускаем
сырой `Exception` дальше `data/` слоя. Ни одно состояние ошибки не должно оставаться
необработанным в `BlocListener`.

## Навигация

`go_router` + `StatefulShellRoute.indexedStack` сохраняет состояние вкладок `/tracker`,
`/schedule`, `/history`. Вне shell (без HUD-панели): `/settings/*`, `/onboarding`,
`/action/edit/:id`, `/interval/edit/:id`. Redirect на `/onboarding`, пока
`onboardingCompleted == false`. Тап по уведомлению — всегда deep-link, включая холодный старт
(`NotificationBloc` разбирает `getNotificationAppLaunchDetails`).

## Локализация

`en` / `uk` / `ru` + `system` (по умолчанию) через `flutter_localizations` + `intl` (файлы
`app/lib/l10n/intl_*.arb`, генерация — `flutter gen-l10n`). Смена языка и темы —
мгновенная, `AppSettingsCubit` подписан на `Stream` из Drift, без перезапуска приложения.
