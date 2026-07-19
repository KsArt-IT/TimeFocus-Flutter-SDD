# Tasks: TimeFocus MVP (Фаза 1)

**Input**: Design documents from `/specs/001-timefocus-mvp/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: включены — обязательны по конституции (принцип VI: каждый Bloc/Cubit покрыт
bloc_test, UseCase-ы с ветвлением — unit-тестами).

**Organization**: задачи сгруппированы по user stories (US1–US8) для независимой реализации
и проверки. Все пути — относительно корня репозитория; код в `app/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: можно выполнять параллельно (разные файлы, нет зависимостей)
- **[Story]**: US1–US8 из spec.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: зависимости и каркас каталогов поверх существующего проекта `app/`

- [X] T001 Добавить в app/pubspec.yaml dev-зависимости `bloc_test`, `mocktail` и зависимости `logger`, `vibration`, `url_launcher`, `app_settings`; `flutter pub get`
- [X] T002 Создать каркас каталогов: app/lib/core/{di,router,theme,constants,utils}, app/lib/shared/{database,enums,widgets}, app/lib/app/shell/widgets, app/lib/features/{tracker,pomodoro,water,schedule,history,settings,notifications,onboarding}/{data/{datasources,mappers,repositories},domain/{entities,repositories,usecases},presentation}
- [X] T003 [P] Константы приложения (порция 200 мл, окно еды ±15 мин, сон-напоминание 30 мин, дефолты сетки 4×5, мл/кг для цели по весу) в app/lib/core/constants/app_constants.dart
- [X] T004 [P] Обёртка logger (запрет print) в app/lib/core/utils/app_logger.dart
- [X] T005 Конфигурация DI get_it+injectable в app/lib/core/di/injection.dart (+ аннотации, `dart run build_runner build` проходит)
- [X] T006 [P] Светлая/тёмная темы в app/lib/core/theme/app_theme.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: БД, энумы, роутер, оболочка приложения, ядро уведомлений — блокируют все истории

**⚠️ CRITICAL**: без этой фазы ни одна история не стартует

- [X] T007 [P] 15 энумов с фабрикой fromIndex(int) в app/lib/shared/enums/ (action_mode.dart, action_status.dart, pomodoro_type.dart, pomodoro_status.dart, pomodoro_after_action.dart, water_reminder_mode.dart, drink_type.dart, notification_type.dart, schedule_event_type.dart, meal_slot.dart, hud_context_type.dart, history_mode.dart, history_period.dart, app_theme_mode.dart, water_goal_mode.dart) по data-model.md
- [X] T008 14 Drift-таблиц по data-model.md (+ поле dayType в ScheduleEvents, + поле pausedBySystem в ActionRunnings) в app/lib/shared/database/tables/
- [X] T009 AppDatabase + MigrationStrategy.onCreate с seed: 12 системных активностей (hudPriority: туалет=4, еда=3, спорт=2, сон=1), 5 напитков, singleton user_settings/water_settings, типовое расписание будни/выходные — в app/lib/shared/database/app_database.dart
- [X] T010 DAO: action_dao, running_dao, history_dao, pomodoro_dao, water_dao, schedule_dao, notification_dao, settings_dao (включая SQL-агрегаты периодов) в app/lib/shared/database/daos/
- [X] T011 go_router: StatefulShellRoute.indexedStack (/tracker, /schedule, /history) + маршруты вне shell (/settings/*, /onboarding, /action/edit/:id, /interval/edit/:id, /more/*) в app/lib/core/router/app_router.dart
- [X] T012 UserSettingsRepository (интерфейс + impl + маппер) в app/lib/features/settings/{domain/repositories,data} и AppSettingsCubit (watch Drift Stream → тема/локаль/формат времени) в app/lib/features/settings/presentation/cubit/app_settings_cubit.dart
- [X] T013 Оболочка: app/lib/app/app_root.dart (MultiBlocProvider-заглушки), app/lib/app/app_material_router.dart (BlocBuilder<AppSettingsCubit> → MaterialApp.router), app/lib/app/root_bloc_listener.dart (каркас), app/lib/app/shell/shell_page.dart (Scaffold + BottomNavBar + место HUD)
- [X] T014 Ядро уведомлений: инициализация flutter_local_notifications + timezone в app/lib/main.dart, NotificationScheduler (интерфейс по contracts/notifications.md: schedule/cancel/cancelByType/rescheduleAll, exact с fallback на inexact — FR-036) в app/lib/features/notifications/{domain,data}, запрос разрешений (SDK 33+/31+) через permission_handler
- [X] T015 [P] Юнит-тесты энумов (fromIndex круговой) в app/test/shared/enums_test.dart
- [X] T016 [P] Тест БД: onCreate seed (12 активностей, напитки, singleton-строки) на NativeDatabase.memory() в app/test/shared/database_seed_test.dart

**Checkpoint**: `flutter analyze` чисто, приложение запускается с пустой оболочкой и вкладками

---

## Phase 3: User Story 1 — Трекер активностей (Priority: P1) 🎯 MVP

**Goal**: старт/пауза/стоп из сетки, карточки с таймерами, параллельный трекинг, группы

**Independent Test**: quickstart.md сценарий 1 — старт из сетки, пауза/возобновление/стоп,
корректный таймер после перезапуска приложения, группы in-place

- [X] T017 [P] [US1] Freezed-сущности ActionNameEntity, RunningWithNameEntity в app/lib/features/tracker/domain/entities/
- [X] T018 [P] [US1] Мапперы Model↔Entity в app/lib/features/tracker/data/mappers/action_mappers.dart
- [X] T019 [US1] ActionNameRepository + ActionRunningRepository (интерфейсы по contracts/repositories.md) в app/lib/features/tracker/domain/repositories/, реализации поверх DAO (start создаёт/находит ActionHistory на дату старта; pause/stop закрывают интервал; поддержка pausedBySystem-флага) в app/lib/features/tracker/data/repositories/
- [X] T020 [US1] StartActionUseCase — вся матрица переходов FR-010/010a/010b (shouldInterruptPomodoro, pauseOthers → пауза остальных с pausedBySystem, исключение перерыва, pendingConfirmation для второго pomodoro) в app/lib/features/tracker/domain/usecases/start_action_usecase.dart
- [X] T021 [US1] Pause/Resume/StopActionUseCase (пауза pomodoro-активности → эффект interrupted FR-018a; автовозобновление pausedBySystem после стопа pauseOthers; стоп → сброс цикла) в app/lib/features/tracker/domain/usecases/
- [X] T022 [US1] ActionBloc (события/состояния/TransitionEffect по contracts/blocs.md; droppable/restartable; isClosed-guard) в app/lib/features/tracker/presentation/bloc/action_bloc.dart
- [X] T023 [P] [US1] Виджет тикающего таймера (Timer.periodic 1 c, перерисовка now−startedAt+accumulated) в app/lib/shared/widgets/ticking_timer.dart
- [X] T024 [US1] TrackerPage: список карточек (иконка, название, таймер, время за день, индикатор цикла, Пауза/Старт/Стоп; на паузе — замороженное время FR-006; сортировка FR-005) в app/lib/features/tracker/presentation/pages/tracker_page.dart + widgets/running_card.dart
- [X] T025 [US1] Сетка активностей: настраиваемый размер, прокрутка при переполнении (FR-009), группы in-place с кнопкой «Назад» (FR-007), пустое состояние в app/lib/features/tracker/presentation/widgets/action_grid.dart
- [X] T026 [US1] Диалог подтверждения прерывания второго Помодоро (отказ — без изменений, FR-011) в app/lib/features/tracker/presentation/widgets/confirm_interrupt_dialog.dart; регистрация ActionBloc в AppRoot
- [X] T027 [P] [US1] Unit-тесты StartActionUseCase: полная матрица (nothing±pauseOthers × pomodoro active/break/idle, системный/ручной breakFor, подтверждение/отказ) в app/test/features/tracker/start_action_usecase_test.dart
- [X] T028 [P] [US1] bloc_test ActionBloc (старт/пауза/стоп/сортировка/pendingConfirmation) в app/test/features/tracker/action_bloc_test.dart
- [X] T029 [P] [US1] DAO-тест running/history: старт→пауза→возобновление→стоп, интервалы и accumulatedSec на in-memory БД в app/test/shared/running_dao_test.dart

**Checkpoint**: US1 работает автономно — MVP готов к демо

---

## Phase 4: User Story 2 — Помодоро (Priority: P2)

**Goal**: циклы работа/перерыв, статусы, afterAction, координация с трекером

**Independent Test**: quickstart.md сценарий 2 — полный цикл с уведомлением, прерывание
туалетом, пауза → interrupted, счётчик цикла сохраняется

- [X] T030 [P] [US2] Сущности PomodoroSessionEntity, PomodoroSettingsEntity + мапперы в app/lib/features/pomodoro/{domain/entities,data/mappers}/
- [X] T031 [US2] PomodoroRepository + PomodoroSettingsRepository (версионируемые настройки: saveNewVersion всегда insert) в app/lib/features/pomodoro/{domain/repositories,data/repositories}/
- [X] T032 [US2] FinishPomodoroIntervalUseCase: completed только системно, выбор short/long перерыва по циклу (FR-014: interrupted не засчитывается, сброс только по «Стоп»), ветки afterAction (FR-018, отложенное авто-действие при закрытом приложении) в app/lib/features/pomodoro/domain/usecases/finish_pomodoro_interval_usecase.dart
- [X] T033 [US2] PomodoroBloc (состояния idle/workRunning/breakRunning/readyToResumeWork по contracts/blocs.md; планирование pomodoroFinished/breakFinished через NotificationScheduler; отмена при interrupted; звук и вибрация при срабатывании по soundEnabled/vibrationEnabled из настроек — пакет vibration) в app/lib/features/pomodoro/presentation/bloc/pomodoro_bloc.dart
- [X] T034 [US2] Координация в app/lib/app/root_bloc_listener.dart: таблица из contracts/blocs.md (pomodoroShouldStart/Stop, readyToResumeWork → ActionStarted(source: system), тост toastification «Помодоро прерван …» FR-012); регистрация PomodoroBloc в AppRoot
- [X] T035 [US2] Индикатор Помодоро на карточке (тип, номер цикла «2/4», обратный отсчёт) + кнопка «Пропустить» в app/lib/features/tracker/presentation/widgets/pomodoro_indicator.dart
- [X] T036 [P] [US2] Unit-тесты FinishPomodoroIntervalUseCase (циклы 3–5, длинный перерыв, afterAction все 5 веток, сохранение счётчика после interrupted) в app/test/features/pomodoro/finish_pomodoro_usecase_test.dart
- [X] T037 [P] [US2] bloc_test PomodoroBloc (старт→finish→break→resume; interrupted при pauseOthers/паузе; skipped) в app/test/features/pomodoro/pomodoro_bloc_test.dart

**Checkpoint**: US1+US2 работают вместе; матрица переходов полностью активна

---

## Phase 5: User Story 3 — Вода и HUD (Priority: P3)

**Goal**: HUD-панель с полоской воды, лог напитков, два режима напоминаний, виджет туалета

**Independent Test**: quickstart.md сценарий 3 — +200 мл по тапу, список по удержанию,
interval-перенос, мигание при Помодоро, приоритет контекстной иконки

- [X] T038 [P] [US3] Сущности WaterHudEntity, WaterSettingsEntity, WaterQuickButtonEntity + мапперы в app/lib/features/water/{domain/entities,data/mappers}/
- [X] T039 [US3] WaterRepository (watchToday с целью дня и нормой к моменту; log с DailyWaterGoal-фиксацией и lastDrankAt) в app/lib/features/water/{domain/repositories,data/repositories}/
- [X] T040 [US3] LogWaterUseCase (лог + interval-перепланирование через NotificationScheduler + туалет-триггер showToiletOnWater) в app/lib/features/water/domain/usecases/log_water_usecase.dart
- [X] T041 [P] [US3] HudContextResolver — чистая функция приоритета Туалет>Еда>Спорт>Сон>пусто, еда по времени суток (MealSlot), флаги туалета в app/lib/features/water/domain/usecases/resolve_hud_context_usecase.dart
- [X] T042 [US3] WaterReminderPlanner: interval-режим (одно уведомление, lastDrankAt+N) и scheduled-режим (все на день, автопропуск ±15 мин от еды, отброс после окна сна — FR-024/025) в app/lib/features/water/domain/usecases/plan_water_reminders_usecase.dart
- [X] T043 [US3] HudCubit (подписки: вода, настройки, контекст; методы по contracts/blocs.md; мигание стакана при активном Помодоро) в app/lib/features/water/presentation/cubit/hud_cubit.dart; регистрация в AppRoot
- [X] T044 [US3] HUD-панель в shell: полоска с делениями/меткой нормы/красной зоной (различимы не только цветом — FR-047), кнопка стакана (тап +порция, long-press список напитков), контекстная иконка с пульсацией (отключаемой) в app/lib/app/shell/widgets/hud_panel.dart
- [X] T045 [US3] Виджет туалета: состояния скрыт/рекомендован/активен, тап → старт «Туалет» (во время перерыва — без прерывания, FR-010b) в app/lib/app/shell/widgets/toilet_context_icon.dart
- [X] T046 [P] [US3] Unit-тесты HudContextResolver (все приоритеты, флаги, слоты еды) в app/test/features/water/hud_context_resolver_test.dart
- [X] T047 [P] [US3] Unit-тесты LogWaterUseCase + WaterReminderPlanner (interval/scheduled, ±15 мин, рекомендация стаканов ceil/max4 — FR-026) в app/test/features/water/water_usecases_test.dart
- [X] T048 [P] [US3] bloc_test HudCubit в app/test/features/water/hud_cubit_test.dart

**Checkpoint**: HUD жив на всех вкладках shell, вода и туалет работают

---

## Phase 6: User Story 4 — Расписание дня (Priority: P4)

**Goal**: таймлайн (план+факт+вода+напоминания), строгие/гибкие события, предупреждения

**Independent Test**: quickstart.md сценарий 4 — строгий обед: warning при старте Помодоро,
принудительное прерывание в точное время, старт активности по тапу

- [X] T049 [P] [US4] ScheduleEventEntity + мапперы в app/lib/features/schedule/{domain/entities,data/mappers}/
- [X] T050 [US4] ScheduleRepository (watchDay по dayType, strictEventsAfter) + интерфейс-задел CalendarDataSource (FR-033) в app/lib/features/schedule/{domain,data}/
- [X] T051 [US4] CheckStrictEventsUseCase: при старте Помодоро eventTime−now < pomodoroDuration → немедленный mealStrictWarning; пересчёт при каждом старте (FR-032) в app/lib/features/schedule/domain/usecases/check_strict_events_usecase.dart
- [X] T052 [US4] Планирование событий дня: mealStrict (точное время, принудительное прерывание через RootBlocListener; старт активности только по тапу — FR-031), mealFlexible (отложить до конца Помодоро, пульсация HUD), sleepReminder за 30 мин в app/lib/features/schedule/domain/usecases/plan_day_events_usecase.dart
- [X] T053 [US4] ScheduleCubit (таймлайн = merge план/факт/вода/напоминания; CRUD) в app/lib/features/schedule/presentation/cubit/schedule_cubit.dart
- [X] T054 [US4] SchedulePage: вертикальный таймлайн с дорожками для параллельных интервалов (FR-030), добавление события с таймлайна, пустое состояние в app/lib/features/schedule/presentation/pages/schedule_page.dart + widgets/
- [X] T055 [P] [US4] Unit-тесты CheckStrictEventsUseCase + plan_day_events (границы: успевает/не успевает, строгое во время перерыва, совпадение с концом интервала — edge cases спеки) в app/test/features/schedule/strict_events_test.dart
- [X] T056 [P] [US4] bloc_test ScheduleCubit в app/test/features/schedule/schedule_cubit_test.dart

**Checkpoint**: расписание управляет уведомлениями и прерываниями

---

## Phase 7: User Story 5 — Уведомления и холодный старт (Priority: P5)

**Goal**: все 9 типов, payload-роутинг warm/cold, очередь отложенных, мьют, reboot

**Independent Test**: quickstart.md сценарий 5 — тап по уведомлению из terminated-состояния
выполняет сценарий; мьют в «Сне»; продление перерыва

- [X] T057 [US5] NotificationRepository (зеркало: insert/delete/deleteByType/pending/markDelivered; не более одного недоставленного на тип+контекст — FR-034a) в app/lib/features/notifications/data/repositories/notification_repository_impl.dart
- [X] T058 [US5] HandleNotificationTapUseCase: payload → intent для всех 9 типов (contracts/notifications.md), устаревший payload → открытие без действия (FR-035), extendBreak (+5 мин по умолчанию, многократно) в app/lib/features/notifications/domain/usecases/handle_notification_tap_usecase.dart
- [X] T059 [US5] Очередь отложенных: при активном Помодоро/мьюте уведомления копятся, после окончания доставляются ВСЕ по очереди (FR-034a); мьют от Сон/Медитация/Молитва и глобального флага (FR-037) в app/lib/features/notifications/domain/usecases/deferred_queue_usecase.dart
- [X] T060 [US5] NotificationBloc: init (getNotificationAppLaunchDetails → cold start), onDidReceiveNotificationResponse, ScheduleRecalculated (sequential), rescheduleAll при старте (FR-035a) в app/lib/features/notifications/presentation/bloc/notification_bloc.dart; регистрация в AppRoot + маршрутизация intent в RootBlocListener
- [X] T061 [US5] Android/iOS конфигурация: разрешения в AndroidManifest (POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED для восстановления после reboot), Darwin-инициализация, notification actions (extendBreak) в app/android/app/src/main/AndroidManifest.xml и app/ios/Runner/
- [X] T062 [P] [US5] Unit-тесты HandleNotificationTapUseCase (все типы, устаревшие payload) в app/test/features/notifications/handle_tap_test.dart
- [X] T063 [P] [US5] Unit-тесты очереди отложенных + правил мьюта в app/test/features/notifications/deferred_queue_test.dart
- [X] T064 [P] [US5] bloc_test NotificationBloc в app/test/features/notifications/notification_bloc_test.dart

**Checkpoint**: SC-003 — 100% тапов ведут к корректному сценарию, включая cold start

---

## Phase 8: User Story 6 — История и отчёты (Priority: P6)

**Goal**: режимы/периоды, шапка, полное редактирование, отчёты-пресеты

**Independent Test**: quickstart.md сценарий 6 — переключение периодов, правка интервала с
предупреждением о пересечении, пересчёт итогов

- [ ] T065 [P] [US6] Сущности HistoryHeaderEntity, HistoryIntervalEntity, HistoryTotalEntity, HistorySessionEntity + мапперы в app/lib/features/history/{domain/entities,data/mappers}/
- [ ] T066 [US6] HistoryRepository: SQL-агрегаты периодов (totalSec без «Сна» — FR-039; Помодоро ✓/✗; вода выпито/цель), saveInterval с OverlapCheck (конец<начала → ValidationFailure; пересечение → warning, сохранено) в app/lib/features/history/data/repositories/history_repository_impl.dart
- [ ] T067 [US6] HistoryCubit (mode/period/anchor навигация, «сегодня») в app/lib/features/history/presentation/cubit/history_cubit.dart
- [ ] T068 [US6] HistoryPage: нижняя панель режимов/периодов/стрелок, шапка, список Интервалы/Итого/Статистика, пустые состояния в app/lib/features/history/presentation/pages/history_page.dart + widgets/
- [ ] T069 [US6] Экран сессии (смена активности, статус, комментарий, удаление с каскадом) в app/lib/features/history/presentation/pages/session_edit_page.dart
- [ ] T070 [US6] Экран редактирования интервала (быстрые кнопки: сейчас/−5/−1/+1/+5; inline-валидация; предупреждение о пересечении) в app/lib/features/history/presentation/pages/interval_edit_page.dart
- [ ] T071 [US6] Экран отчётов: 7 пресетов периодов + графики fl_chart (время по дням, вода) в app/lib/features/history/presentation/pages/reports_page.dart
- [ ] T072 [P] [US6] DAO/repo-тесты агрегатов (без «Сна», сессия через полночь в дне старта, OverlapCheck) в app/test/features/history/history_repository_test.dart
- [ ] T073 [P] [US6] bloc_test HistoryCubit в app/test/features/history/history_cubit_test.dart

**Checkpoint**: SC-010 — агрегаты корректны, правки мгновенно пересчитывают итоги

---

## Phase 9: User Story 7 — Настройки (Priority: P7)

**Goal**: раздел «Больше» и все экраны настроек; мгновенная тема/язык

**Independent Test**: quickstart.md сценарий 7 — смена языка мгновенно, создание активности,
системная не удаляется, новые времена Помодоро со следующей сессии

- [ ] T074 [US7] Экран «Больше» (список разделов + заглушки «Учетная запись»/«О программе» с package_info_plus — FR-045) в app/lib/features/settings/presentation/pages/more_page.dart
- [ ] T075 [P] [US7] Системные настройки (тема/язык/формат 12/24/секунды) через AppSettingsCubit в app/lib/features/settings/presentation/pages/system_settings_page.dart
- [ ] T076 [US7] Редактор активностей: список, создание/правка (имя, описание, иконка FontAwesome-пикер, flutter_colorpicker, режим, тип Помодоро, breakAction-выбор, длительность), архивация; системные — без удаления (FR-043, FR-008) в app/lib/features/settings/presentation/pages/actions_settings_page.dart + action_edit_page.dart
- [ ] T077 [P] [US7] Настройки Помодоро (времена 3 типов, циклы 3–5, afterAction, звук/вибрация; сохранение = новая версия) в app/lib/features/settings/presentation/pages/pomodoro_settings_page.dart
- [ ] T078 [P] [US7] Настройки воды (цель по весу/вручную, режим, интервал/times[], напитки, флаги туалета, окно от подъёма до сна) в app/lib/features/settings/presentation/pages/water_settings_page.dart
- [ ] T079 [P] [US7] Настройки напоминаний (вкл/выкл, статус разрешений, переход в системные настройки через app_settings) в app/lib/features/settings/presentation/pages/reminders_settings_page.dart
- [ ] T080 [P] [US7] Настройки расписания дня (будни/выходные, время+строгость событий) в app/lib/features/settings/presentation/pages/schedule_settings_page.dart
- [ ] T081 [US7] SettingsCubit (агрегирующий для экранов настроек) в app/lib/features/settings/presentation/cubit/settings_cubit.dart; отображение сетки columnCount/rowCount 1–5 (FR-009)
- [ ] T082 [P] [US7] bloc_test AppSettingsCubit (мгновенная смена, system-локаль) + SettingsCubit в app/test/features/settings/settings_cubits_test.dart

**Checkpoint**: SC-008 — тема/язык мгновенно на всех экранах

---

## Phase 10: User Story 8 — Онбординг (Priority: P8)

**Goal**: пропускаемый первый запуск, имя опционально, полная работоспособность после skip

**Independent Test**: quickstart.md сценарий 8 — skip → трекер с 12 активностями; повторный
запуск без онбординга

- [ ] T083 [US8] OnboardingCubit (шаги, skip, запись onboardingCompleted, опциональное имя) в app/lib/features/onboarding/presentation/cubit/onboarding_cubit.dart
- [ ] T084 [US8] Страницы онбординга (описание функций, ввод имени, запрос разрешения на уведомления с обработкой отказа — FR-036/044) в app/lib/features/onboarding/presentation/pages/onboarding_page.dart
- [ ] T085 [US8] Redirect в app/lib/core/router/app_router.dart: onboardingCompleted == false → /onboarding
- [ ] T086 [P] [US8] bloc_test OnboardingCubit в app/test/features/onboarding/onboarding_cubit_test.dart

**Checkpoint**: SC-009 — первый запуск активности ≤ 30 c после skip

---

## Phase 11: Polish & Cross-Cutting Concerns

- [ ] T087 [P] Заполнить локализации всех строк (en/uk/ru) в app/lib/l10n/intl_*.arb: активности, напитки, уведомления, экраны; переименованные пользователем не переводятся (FR-042)
- [ ] T088 [P] Доступность FR-047: тап-цели ≥48dp, Semantics-метки сетки/HUD, отключение пульсации при reduce-motion — пройтись по tracker/HUD/history виджетам
- [ ] T089 [P] Пустые состояния и единый паттерн ошибок FR-046 (тост toastification + inline у форм) — пройтись по всем страницам
- [ ] T090 Смена системного времени/пояса: защита от отрицательных интервалов (clamp ≥0) в таймере и istории; пересоздание уведомлений по локальному времени (edge cases спеки) в app/lib/core/utils/time_guard.dart + использование
- [ ] T091 Прогон quickstart.md сценариев 1–8 на устройстве/эмуляторе (Android + iOS), фиксация результатов в specs/001-timefocus-mvp/quickstart.md (отметки)
- [ ] T092 Финальный гейт конституции: `dart run build_runner build`, `flutter analyze` чисто, `dart format` (100 симв.), `flutter test` зелёный, нет print/magic numbers/хардкода строк

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 → Phase 2**: строго последовательно (T005 DI нужен всем; T008→T009→T010 цепочка)
- **Phase 2 блокирует все US**: T007–T014 обязательны до любых историй
- **US1 (Phase 3)**: только Foundational; T019→T020/T021→T022→T024/T025/T026
- **US2 (Phase 4)**: требует US1 (ActionBloc, StartActionUseCase-эффекты)
- **US3 (Phase 5)**: требует Foundational + T014; эффекты Помодоро (мигание) — интеграция с US2, но лог воды/HUD тестируются без него
- **US4 (Phase 6)**: требует US2 (прерывание строгими событиями) и T014
- **US5 (Phase 7)**: требует US2–US4 (обрабатывает их уведомления); ядро T014 уже в Foundational
- **US6 (Phase 8)**: требует US1 (данные истории); Помодоро-счётчики шапки — US2
- **US7 (Phase 9)**: независим после Foundational (T012 уже есть); редактор активностей взаимодействует с US1-данными
- **US8 (Phase 10)**: независим после Foundational
- **Phase 11**: после всех выбранных историй

### Parallel Opportunities

- Phase 1: T003, T004, T006 параллельно после T002
- Phase 2: T007 ∥ T008; T015, T016 ∥ после своих целей
- Внутри каждой US: сущности/мапперы [P], все тесты [P] после реализации
- После Foundational: US7 и US8 можно вести параллельно с US1–US6 (разные каталоги)
- US3 (вода) параллельно с US2 (помодоро) — пересечение только в RootBlocListener (T034/T043 — координировать)

## Parallel Example: User Story 1

```bash
# Параллельно после T016:
Task: "T017 Freezed-сущности tracker"
Task: "T023 Виджет тикающего таймера"
# Параллельно после T022–T026:
Task: "T027 unit StartActionUseCase"
Task: "T028 bloc_test ActionBloc"
Task: "T029 DAO-тест running/history"
```

## Implementation Strategy

### MVP First (US1 Only)

1. Phase 1 → Phase 2 → Phase 3 (US1)
2. СТОП: прогнать quickstart сценарий 1 — трекер сам по себе ценен (MVP)

### Incremental Delivery

Порядок: US1 → US2 → US3 → US4 → US5 → US6 → US7 → US8 → Polish.
Каждая история завершается своим checkpoint-ом (quickstart-сценарием) и зелёными тестами;
US7/US8 можно подтянуть раньше при необходимости демо.

## Notes

- Тесты обязательны (конституция, принцип VI); коммит после каждой задачи/логической группы
  в формате Conventional Commits
- После изменения аннотаций/таблиц — `dart run build_runner build`
- Bloc не импортирует Bloc: вся координация — только T034 (RootBlocListener)
