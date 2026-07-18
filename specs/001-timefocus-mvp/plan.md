# Implementation Plan: TimeFocus MVP (Фаза 1)

**Branch**: `001-timefocus-mvp` | **Date**: 2026-07-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-timefocus-mvp/spec.md`

## Summary

Мобильное offline-first приложение (Android/iOS): трекер активностей с параллельным трекингом,
Помодоро с единой матрицей переходов, трекер воды с HUD-панелью, расписание дня со
строгими/гибкими событиями, локальные уведомления с обработкой холодного старта, история с
редактированием и отчёты. Технический подход: Flutter + BLoC/Cubit + Drift (реактивные
Stream-запросы) + Clean Architecture (Feature First), без фоновых процессов — время
вычисляется как `now − startedAt + accumulatedSec`, уведомления планируются заранее через
`flutter_local_notifications` + `timezone`. Координация глобальных Bloc-ов — только через
`RootBlocListener`.

## Technical Context

**Language/Version**: Dart (SDK ^3.12.0), Flutter stable (проект уже инициализирован в `app/`)

**Primary Dependencies**: flutter_bloc 9.x + bloc_concurrency, drift 2.34 + drift_flutter +
sqlite3_flutter_libs, get_it + injectable (+generator), freezed 3.x + json_serializable,
go_router 17.x, flutter_local_notifications 22.x + flutter_timezone + timezone,
permission_handler + device_info_plus, font_awesome_flutter, flutter_colorpicker, fl_chart,
toastification (снэкбары/тосты), build_runner

**Storage**: Drift (SQLite), 14 таблиц по PRD; singleton-строки для user_settings и
water_settings; реактивные Stream-запросы для UI. Supabase — вне объёма MVP (задел в UI)

**Testing**: flutter_test + bloc_test + mocktail (dev-зависимости добавить), unit-тесты
UseCase-ов, bloc_test для каждого Bloc/Cubit

**Target Platform**: Android (minSdk по flutter_local_notifications, разрешения SDK 31+/33+),
iOS 13+

**Project Type**: mobile-app — Flutter-проект в каталоге `app/`

**Performance Goals**: старт активности < 1 c (SC-001); обновление таймеров на экране 1 раз/с
без пересборки всего дерева; HUD обновляется мгновенно при логе воды

**Constraints**: полностью offline (SC-006); без фоновых изолятов/сервисов; точность таймера
после перезапуска ≤ 1 с (SC-002); payload уведомлений самодостаточен для cold start (SC-003);
мгновенная смена темы/языка (SC-008)

**Scale/Scope**: один пользователь, локальные данные (~10³–10⁴ записей истории/год);
~25 экранов/страниц; 8 фич-модулей; 5 глобальных Bloc-ов

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Принцип | Статус | Примечание |
|---|---------|--------|------------|
| I | Clean Architecture + Feature First | ✅ PASS | Структура `core/ shared/ app/ features/*` c data/domain/presentation; domain — чистый Dart |
| II | Offline-first без фоновых процессов | ✅ PASS | Drift + формула таймера; уведомления через tz.TZDateTime заранее; Supabase вне MVP |
| III | Дисциплина BLoC/Cubit | ✅ PASS | Freezed sealed-состояния, трансформеры, `isClosed`-guard, координация через RootBlocListener |
| IV | Result\<T\> / AppFailure | ✅ PASS | Уже реализованы в `app/lib/core/result`, `app/lib/core/errors` |
| V | Бизнес-инварианты в одном месте | ✅ PASS | `StartActionUseCase.shouldInterruptPomodoro`, приоритет HUD, режимы воды — по одной точке определения (см. contracts/) |
| VI | Тестирование — гейт | ✅ PASS | bloc_test/mocktail добавляются в dev deps; тесты UseCase-ов обязательны |
| VII | Локализация и темы с первого дня | ✅ PASS | l10n (en/uk/ru) уже подключена; AppSettingsCubit на Drift Stream |
| — | Технологические ограничения | ✅ PASS | Запрещённых пакетов нет; `toastification` — доп. UI-пакет, не конфликтует |

Отклонения, требующие Complexity Tracking: нет.

Замечание (не нарушение): в `app/pubspec.yaml` отсутствуют `supabase_flutter`, `logger`,
`vibration`, `url_launcher`, `share_plus`, `app_settings`, `bloc_test`, `mocktail` из списка
CLAUDE.md — добавляются по мере надобности задачами; Supabase в MVP не добавляется вовсе.

## Project Structure

### Documentation (this feature)

```text
specs/001-timefocus-mvp/
├── plan.md              # этот файл
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # Phase 1 — внутренние контракты
│   ├── blocs.md         # глобальные Bloc-и: события/состояния/координация
│   ├── notifications.md # типы уведомлений, payload, deep-link
│   └── repositories.md  # интерфейсы репозиториев domain-слоя
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
app/                               # существующий Flutter-проект
├── lib/
│   ├── main.dart                  # init: timezone, DI, runApp
│   ├── gen/                       # сгенерированная локализация (есть)
│   ├── l10n/                      # arb en/ru/uk (есть)
│   ├── core/
│   │   ├── result/                # Result<T> (есть)
│   │   ├── errors/                # AppFailure + наследники (есть)
│   │   ├── di/                    # get_it + injectable конфигурация
│   │   ├── router/                # go_router: StatefulShellRoute + deep-links
│   │   ├── theme/                 # светлая/тёмная темы
│   │   ├── constants/             # AppConstants (порции, дефолты)
│   │   └── utils/                 # logger, время/форматирование
│   ├── shared/
│   │   ├── database/              # AppDatabase, 14 таблиц, DAO, seed системных активностей
│   │   ├── enums/                 # все энумы с fromIndex(int)
│   │   └── widgets/               # переиспользуемые виджеты
│   ├── app/
│   │   ├── app_root.dart          # MultiBlocProvider глобальных Bloc-ов
│   │   ├── app_material_router.dart
│   │   ├── root_bloc_listener.dart
│   │   └── shell/                 # ShellPage: HudPanel + BottomNavBar
│   └── features/
│       ├── tracker/               # ActionBloc, сетка, карточки, StartActionUseCase
│       ├── pomodoro/              # PomodoroBloc, циклы, настройки-снимки
│       ├── water/                 # HudCubit, лог воды, напитки, цели
│       ├── schedule/              # ScheduleCubit, таймлайн, строгие/гибкие события
│       ├── history/               # HistoryCubit, режимы/периоды, редактирование
│       ├── settings/              # SettingsCubit, AppSettingsCubit
│       ├── notifications/         # NotificationBloc, планировщик, payload-роутинг
│       └── onboarding/            # OnboardingCubit
└── test/
    ├── core/                      # Result, утилиты
    ├── features/<name>/           # bloc_test + unit UseCase-ов по фичам
    └── shared/                    # мапперы, энумы, DAO (in-memory sqlite)
```

**Structure Decision**: mobile-app, единственный Flutter-проект в `app/` (уже создан).
Feature First + Clean Architecture по конституции; каждая фича — `data/domain/presentation`.
БД и энумы — в `shared/`, т.к. используются ≥2 фичами.

## Complexity Tracking

Нарушений Constitution Check нет — раздел пуст.

## Post-Design Constitution Re-Check

После Phase 1 (data-model, contracts): нарушений не выявлено. Единые точки определения
инвариантов зафиксированы в contracts/ (StartActionUseCase, HudContextResolver,
WaterReminderPlanner, NotificationScheduler). Все Stream-подписки UI идут через Drift
watch-запросы → Cubit, что соответствует принципам II и III.
