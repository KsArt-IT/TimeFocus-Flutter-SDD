# TimeFocus — CLAUDE.md

Мобильное приложение для гармонизации продуктивности и здоровья.
Трекер времени + Помодоро + вода + расписание дня — без конфликтов между ними.

---

## Стек

**Flutter / Dart · BLoC/Cubit · Supabase/Drift (SQLite) · Clean Architecture · Online/Offline**

| Категория | Пакеты |
|---|---|
| Состояние | `flutter_bloc`, `bloc_concurrency` |
| БД online | `supabase_flutter` |
| БД ofline | `drift`, `sqlite3_flutter_libs` |
| DI | `get_it`, `injectable`, `injectable_generator` |
| Модели | `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation` |
| Навигация | `go_router` |
| Уведомления | `flutter_local_notifications`, `flutter_timezone`, `timezone` |
| Разрешения | `permission_handler`, `app_settings`, `device_info_plus` |
| UI | `font_awesome_flutter`, `fl_chart`, `flutter_native_splash`, `flutter_launcher_icons` (dev) |
| Авторизация | `supabase_auth_ui` |
| Утилиты | `collection`, `path_provider`, `logger`, `package_info_plus`, `vibration`, `url_launcher`, `share_plus` |
| Кодогенерация | `build_runner` (dev) |
| Тесты | `bloc_test`, `mocktail` (dev) |

**Не используем:** `dartz`, `rxdart`, `either_dart` — используем собственный `Result<T>`.

---

## Архитектура — Feature First + Clean Architecture

```
lib/
├── core/              # технические утилиты (DI, router, theme, result, error, utils)
├── shared/            # переиспользуется в ≥2 фичах (database, enums, widgets)
├── app/               # оболочка приложения
│   ├── app_root.dart             # MultiBlocProvider (global Bloc-ов) + WidgetsBindingObserver
│   │                              # (resumed → NotificationBloc.initialized() = rescheduleAll)
│   ├── app_material_router.dart  # MaterialApp.router + тема + локаль
│   ├── root_bloc_listener.dart   # координатор между Global Bloc-ами
│   └── shell/
│       ├── shell_page.dart       # Scaffold + HudPanel + BottomNavBar
│       └── widgets/
└── features/
    ├── tracker/       # запуск/пауза/стоп активностей → ActionBloc
    ├── pomodoro/      # Помодоро-таймер → PomodoroBloc
    ├── water/         # трекер воды + HUD → HudCubit
    ├── schedule/      # расписание дня → ScheduleCubit
    ├── history/       # история → HistoryCubit
    ├── settings/      # все настройки → SettingsCubit, AppSettingsCubit
    ├── notifications/ # планировщик → NotificationBloc
    └── onboarding/    # первый запуск → OnboardingCubit
```

Каждая фича содержит `data/`, `domain/`, `presentation/`.

### Правила слоёв
- `domain/` — только Dart, никаких Flutter/Drift импортов
- `Cubit/Bloc` — зависит только от абстрактных репозиториев из `domain/`
- `Bloc` не импортирует другой `Bloc` — координация только через `RootBlocListener`
- `presentation/` фичи не импортирует `presentation/` другой фичи

---

## Структура каждой фичи

```
features/<name>/
├── data/
│   ├── datasources/   # DAO-обёртки
│   ├── mappers/       # Model->Domain entity, Domain entity->Model
│   └── repositories/  # <Name>RepositoryImpl
├── domain/
│   ├── entities/      # Freezed, без аннотаций Drift
│   ├── repositories/  # abstract interface class
│   └── usecases/      # бизнес-логика
└── presentation/
    ├── bloc/          # *Bloc (сложные события) или cubit/ (*Cubit)
    ├── pages/         # *Page
    └── widgets/       # виджеты фичи
```

---

## Global Bloc-и (синглтоны, живут всё время приложения)

| Bloc/Cubit | Фича | Ответственность |
|---|---|---|
| `AppSettingsCubit` | settings | тема + язык, читает Drift Stream |
| `ActionBloc` | tracker | запуск/пауза/стоп активностей |
| `PomodoroBloc` | pomodoro | Помодоро-сессии и перерывы |
| `HudCubit` | water | полоска воды + контекстная иконка |
| `NotificationBloc` | notifications | планирование уведомлений |

Создаются в `AppRoot` через `MultiBlocProvider`. Координируются через `RootBlocListener`.

---

## Ключевые правила бизнес-логики

### Переходы активностей
```dart
// Единственное место определения — StartActionUseCase
bool shouldInterruptPomodoro(ActionNameModel action) =>
  action.mode == ActionMode.pomodoro.index ||
  action.mode == ActionMode.breakFor.index ||
  action.pauseOthers;

// Системный PomodoroWorkIntervalFinished — НЕ прерывает Помодоро
```

### Координация Bloc-ов (RootBlocListener)
```
PomodoroBloc.readyToResumeWork(id) → ActionBloc.start(id)
PomodoroBloc.breakRunning          → HudCubit.onPomodoroBreakStarted()
ActionBloc.pomodoroInterrupted     → ScaffoldMessenger снэкбар
```

### Таймер
```dart
// Нет фонового процесса. Всегда через core/utils/time_guard.dart (ClockGuard extension),
// чтобы откат системных часов/смена пояса не давала отрицательный интервал:
final elapsed = now.secondsSince(startedAt) + accumulatedSec; // clamp ≥0
final delay = fireAt.delayFrom(now);                          // Timer-delay, clamp ≥ Duration.zero
```

### Вода — два режима
- `interval` → `nextReminder = lastDrankAt + N мин`, пересоздаётся после питья
- `scheduled` → все уведомления дня планируются сразу, питьё таймер не сбрасывает

### HUD контекстная иконка — приоритет
```
Туалет (4) > Еда (3) > Спорт (2) > Сон (1) > пусто (0)
```
Туалет показывается только если `showToiletOnWater` или `showToiletOnBreak` включены.

---

## Тема и локаль

`AppSettingsCubit` подписан на `UserSettingsRepository.watch()` (Drift Stream).
`AppMaterialRouter.dart` через `BlocBuilder<AppSettingsCubit>` передаёт `themeMode` и `locale` в `MaterialApp.router`.
Смена темы/языка — мгновенная, без перезапуска.

```dart
// Поддерживаемые языки: 'en', 'uk', 'ru', 'system' (default)
// Поддерживаемые темы: AppThemeMode.dark, .light, .system (default)
```

---

## Result<T> и ошибки

```dart
// core/result/result.dart — собственный sealed class
result.fold(
  success: (value) => emit(state.loaded(value)),
  failure: (e) => emit(state.error(e)),
);

// core/errors/app_failure.dart — В Result.failure всегда AppFailure, не сырой Exception
sealed class AppFailure implements Exception {
  String localizedMessage(AppLocalizations locale) => message; // переопределяется у failure с code
}
// Подклассы: Unknown · Platform · Initialization · Network · Validation · Settings
// Action · Pomodoro · Schedule · Water · Database (code: uniqueViolation/entityNotFound/savingError)
// Notification (code: notFound/notLaunch)

// core/errors/safe_call_mixin.dart — репозитории оборачивают вызовы датасорсов:
mixin SafeCallMixin {
  Future<Result<T>> safeCall<T>(AsyncValueGetter<T> invoke);   // -> success/failure(AppFailure)
  Future<Result<void>> voidSafeCall(AsyncCallback invoke);
}
```

### Обязательная поверхность ошибок (FR-046)
Ни один `*State.error(AppFailure)`/`*Error(...)` не должен молча проглатываться в
`BlocListener`/`listenWhen` — либо тост (глобальные/фоновые ошибки), либо inline-текст
у формы (валидация). Паттерн тоста — только в `RootBlocListener` через toastification:
```dart
void _showFailureToast(BuildContext context, AppFailure failure) {
  toastification.show(
    context: context,
    type: ToastificationType.error,
    title: Text(failure.localizedMessage(AppLocalizations.of(context))),
    autoCloseDuration: const Duration(seconds: 4),
  );
}
```
Каждый новый Bloc/Cubit с состоянием ошибки должен получить `BlocListener` в
`RootBlocListener`, вызывающий этот тост (или экранный inline-виджет для форм).

---

## Bloc/Cubit — шаблоны

```dart
// Состояния — Freezed sealed
@freezed
sealed class FeatureState with _$FeatureState {
  const factory FeatureState.initial() = _Initial;
  const factory FeatureState.loading() = _Loading;
  const factory FeatureState.loaded(FeatureData data) = _Loaded;
  const factory FeatureState.error(AppFailure e) = _Error;
}

// bloc_concurrency трансформеры:
on<StartAction>(_onStart, transformer: droppable());    // старт/стоп
on<LoadActions>(_onLoad,  transformer: restartable());  // загрузка
on<LogWater>(_onLog,      transformer: sequential());   // очередь

// После await — обязательно:
if (isClosed) return;

// Side-effects (навигация, снэкбары) — только в listener, не в emit

// Для BlocConsumer, BlocBuilder при использовать состояния
=> state.maybeWhen(), //maybeMap, mapOrNull
```
---

## Уведомления

```dart
// main.dart — инициализация timezone:
tz.initializeTimeZones();
tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));

// Планировать только через tz.TZDateTime
// Разрешения по версии Android:
// SDK 33+ → POST_NOTIFICATIONS
// SDK 31+ → SCHEDULE_EXACT_ALARM

// Payload содержит всё для cold start:
{'actionId': 1, 'breakActionId': 2, 'pomodoroCount': 3}
```

`AppRoot` — `WidgetsBindingObserver`: на `AppLifecycleState.resumed` шлёт
`NotificationEvent.initialized()` повторно → `rescheduleAll` пересчитывает все
`scheduledAt` по текущему локальному времени (защита от смены часового пояса/времени,
пока приложение было в фоне).

---

## Доступность (FR-047)

```dart
// core/constants/app_constants.dart:
AppConstants.minTapTargetDp // = 48, всегда SizedBox(width/height: ...) вокруг icon-only кнопок

// Semantics на любой icon-only интерактивный виджет (сетка, HUD, таймлайн):
Semantics(button: true, label: l10n.xxx, child: ...)

// Пульсация/мигание (HUD-иконки, туалет) — только если разрешено reduce-motion:
// core/utils/motion_utils.dart
if (shouldAnimate(context)) /* AnimatedScale/AnimatedOpacity */ else /* статичный child */
```

---

## Навигация

```dart
// StatefulShellRoute.indexedStack — сохраняет стейт вкладок
// Маршруты в shell: /tracker, /schedule, /history
// Вне shell (без HUD): /settings, /onboarding, /action/edit, /interval/edit
// Deep-link при тапе на уведомление — обязателен
```

---

## Энумы (shared/enums/)

Все с `fromIndex(int)` фабрикой. В БД хранится `int`.

`ActionMode` · `ActionStatus` · `PomodoroType` · `PomodoroStatus` · `PomodoroAfterAction`
`WaterReminderMode` · `DrinkType` · `NotificationType` · `ScheduleEventType` · `DayType`
`MealSlot` · `HudContextType` · `HistoryMode` · `HistoryPeriod` · `AppThemeMode` · `WaterGoalMode`

---

## БД (Drift) — 14 таблиц

`action_names` · `action_runnings` · `action_histories` · `action_history_intervals`
`pomodoro_sessions` · `pomodoro_settings`
`water_logs` · `water_settings` · `water_quick_buttons` · `water_reminder_times` · `daily_water_goals`
`schedule_events` · `notifications` · `user_settings`

Системные активности (isSystem=true): Work · Break · Rest · Sleep · Toilet · Meal · Sport · Warm-up · Walk · Meditation · Medicine.

---

## Стиль кода

```dart
// ✓ const везде где возможно
// ✓ Виджеты — классы, не _buildXxx() методы
// ✓ logger вместо print/debugPrint
// ✓ Named параметры для bool в публичных API
// ✓ Одинарные кавычки, 100 символов максимум
```

### Константы — два файла, не путать
- `core/constants/app_constants.dart` — бизнес-константы (мл, минуты, размеры сетки, лимиты)
- `core/constants/app_dimens.dart` — UI-константы (отступы `insetNx`, радиусы `radiusNx`,
  `bottomPaddingX`)

Новое магическое число — всегда в один из этих файлов, не инлайн.

---

## Генерация кода

```bash
dart run build_runner build
```

После изменения: `@freezed`, `@injectable`, `@JsonSerializable`, Drift-таблиц.

---

## Чеклист перед коммитом

- [ ] `flutter analyze` — чисто
- [ ] `dart format` — применён
- [ ] `flutter test` — все проходят
- [ ] `build_runner build` — если менялись аннотации
- [ ] Нет `print`, magic numbers, хардкоженных строк
- [ ] Новый Bloc/Cubit покрыт `bloc_test`
- [ ] `Result.failure` содержит `Exception`
- [ ] Состояние ошибки поверхностно (тост в `RootBlocListener` или inline у формы) — не проглочено
- [ ] Icon-only кнопки: `SizedBox(AppConstants.minTapTargetDp)` + `Semantics(label: ...)`
- [ ] Пульсация/анимация — через `shouldAnimate(context)` (reduce-motion)

---

## Коммиты
Делай комиты простыми, не рассписывай все. По необходимости добавляй "Co-Authored-By: Claude Sonnet 5 noreply@anthropic.com"

```
feat: add water reminder interval mode
fix: pomodoro not interrupted on meal start
refactor: extract StartActionUseCase
test: cover HudCubit water log scenarios
```
