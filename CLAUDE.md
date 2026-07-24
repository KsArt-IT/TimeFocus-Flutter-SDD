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

### Исходники pub-пакетов

Не искать по всему диску (`find /`). Исходники уже скачаны в `~/.pub-cache/hosted/pub.dev/`,
по одной папке на `<пакет>-<версия>`. Версию брать из `app/pubspec.lock`:

```bash
grep -A2 "^  <package>:" app/pubspec.lock   # находит установленную версию
ls ~/.pub-cache/hosted/pub.dev/<package>-<версия>/
```

---

## Архитектура

Feature First + Clean Architecture (`data` / `domain` / `presentation` внутри каждой фичи).

| Нужно | Файл |
|---|---|
| Быстрый старт: структура фичи, чеклист «как добавить фичу» | [.project/architecture/architecture-brief.md](.project/architecture/architecture-brief.md) |
| Полная архитектура: Global Bloc-и, координация RootBlocListener, таймер, Result/AppFailure, шаблоны Bloc/Cubit, уведомления, доступность, навигация | [.project/architecture/architecture-full.md](.project/architecture/architecture-full.md) |

### Правила слоёв (коротко)
- `domain/` — только Dart, никаких Flutter/Drift импортов
- `Cubit/Bloc` — зависит только от абстрактных репозиториев из `domain/`
- `Bloc` не импортирует другой `Bloc` — координация только через `RootBlocListener`
- `presentation/` фичи не импортирует `presentation/` другой фичи

---

## Требования по фичам (PRD)

Что должна делать фича — не в коде, а в требованиях. Один файл на фичу вместо всего PRD:

| Фича | Файл требований |
|---|---|
| Обзор проекта, стек, навигация | [.project/prd/00-overview.md](.project/prd/00-overview.md) |
| tracker (экран «Трекер», системные активности, переходы) | [.project/prd/01-requirements-tracker.md](.project/prd/01-requirements-tracker.md) |
| pomodoro | [.project/prd/02-requirements-pomodoro.md](.project/prd/02-requirements-pomodoro.md) |
| schedule | [.project/prd/03-requirements-schedule.md](.project/prd/03-requirements-schedule.md) |
| water (+ виджет туалета) | [.project/prd/04-requirements-water.md](.project/prd/04-requirements-water.md) |
| notifications | [.project/prd/05-requirements-notifications.md](.project/prd/05-requirements-notifications.md) |
| history | [.project/prd/06-requirements-history.md](.project/prd/06-requirements-history.md) |
| settings / «Больше» / аккаунт / отчёты | [.project/prd/07-requirements-settings.md](.project/prd/07-requirements-settings.md) |
| onboarding | [.project/prd/08-requirements-onboarding.md](.project/prd/08-requirements-onboarding.md) |

---

## Энумы (shared/enums/)

Все с `fromIndex(int)` фабрикой (кроме `ScheduleEventType` — хранится по имени). В БД хранится `int`.

`ActionMode` · `ActionStatus` · `PomodoroType` · `PomodoroStatus` · `PomodoroAfterAction`
`WaterReminderMode` · `DrinkType` · `NotificationType` · `ScheduleEventType` · `DayType`
`MealSlot` · `HistoryMode` · `HistoryPeriod` · `AppThemeMode` · `WaterGoalMode`

Детали каждого enum'а, значения и сверка с PRD — [.project/prd/09-enums.md](.project/prd/09-enums.md).

---

## БД (Drift)

| Нужно | Файл |
|---|---|
| Список таблиц (имена, файлы, группировка по фиче) | [.project/architecture/database-tables.md](.project/architecture/database-tables.md) |
| Полная структура таблиц (колонки, типы, дефолты, сверка с PRD) | [.project/prd/10-database-tables.md](.project/prd/10-database-tables.md) |
| ER-диаграмма (drawio, импортируется в app.diagrams.net) | [.project/architecture/timefocus_er.drawio](.project/architecture/timefocus_er.drawio) |

---

## Стиль кода

```dart
// ✓ const везде где возможно
// ✓ Виджеты — классы, не _buildXxx() методы
// ✓ logger вместо print/debugPrint
// ✓ Named параметры для bool в публичных API
// ✓ Одинарные кавычки, 100 символов максимум
```

### Именование

| Тип | Стиль | Пример |
|---|---|---|
| Файлы | snake_case | `action_cubit.dart` |
| Классы | PascalCase | `ActionCubit` |
| Переменные / функции | camelCase | `startTracking()` |
| Константы | lowerCamelCase + const | `const defaultWaterGoalMl` |
| Private члены | `_` prefix | `_repository` |
| Булевы переменные | вспомогательный глагол | `isLoading`, `hasError`, `pauseOthers` |

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
