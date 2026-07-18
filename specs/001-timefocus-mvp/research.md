# Research — TimeFocus MVP (Фаза 1)

**Date**: 2026-07-18. Все NEEDS CLARIFICATION из Technical Context отсутствовали (стек
зафиксирован конституцией и существующим проектом `app/`); исследование сосредоточено на
рискованных технических решениях.

## R1. Таймер без фонового процесса

- **Decision**: единственный источник истины — БД (`startedAt`, `accumulatedSec`,
  `pausedAt`). UI-таймер — `Timer.periodic(1s)` в presentation-слое, который только
  перерисовывает `now.difference(startedAt) + accumulatedSec`; при `resume`/cold start
  значение восстанавливается из БД без потерь. Никаких изолятов, foreground-сервисов, WorkManager.
- **Rationale**: требование PRD/конституции (принцип II); точность ≤1 c достигается
  вычислением, а не тиканьем; нулевой расход батареи в фоне.
- **Alternatives considered**: foreground service (Android) — отвергнут: сложность,
  батарея, iOS-паритет невозможен; сохранение «тиков» в БД — отвергнуто: избыточные записи.

## R2. Планирование уведомлений (flutter_local_notifications 22.x)

- **Decision**: `zonedSchedule` с `tz.TZDateTime` + `AndroidScheduleMode.exactAllowWhileIdle`
  (fallback на `inexactAllowWhileIdle`, если `SCHEDULE_EXACT_ALARM` не выдан). Каждое
  запланированное уведомление зеркалируется в таблицу `notifications` (id = notificationId)
  для отмены/переноса. Пересоздание всех отложенных уведомлений: при старте приложения,
  смене расписания, старте/остановке Помодоро.
- **Rationale**: exact-alarm нужен строгим событиям и концу Помодоро-интервала; таблица-зеркало
  делает состояние планировщика восстановимым и тестируемым.
- **Alternatives considered**: push/backend — запрещён PRD; `Timer` в приложении — не работает
  при закрытом приложении.

## R3. Cold start / deep-link от уведомлений

- **Decision**: `getNotificationAppLaunchDetails()` в bootstrap → парсинг JSON payload →
  `NotificationBloc` диспетчеризует сценарий через go_router (deep-link) и события глобальных
  Bloc-ов после построения `AppRoot`. Тап по уведомлению в работающем приложении — тот же
  путь через `onDidReceiveNotificationResponse`.
- **Rationale**: единый обработчик payload для warm/cold старта (SC-003); payload
  самодостаточен (FR-035).
- **Alternatives considered**: обработка прямо в `main()` до DI — отвергнута: Bloc-и ещё не
  созданы, дублирование логики.

## R4. Реактивность настроек (тема/язык без перезапуска)

- **Decision**: `UserSettingsRepository.watch()` (Drift `watchSingle`) → `AppSettingsCubit` →
  `BlocBuilder` в `AppMaterialRouter` передаёт `themeMode`/`locale` в `MaterialApp.router`.
- **Rationale**: паттерн уже описан в конституции; Drift Stream даёт мгновенную реакцию и
  персистентность одним механизмом.
- **Alternatives considered**: SharedPreferences + ValueNotifier — второй механизм хранения
  рядом с Drift, лишняя сущность.

## R5. Схема Drift и производные данные

- **Decision**: 14 таблиц строго по PRD (раздел «Ключевые таблицы»). Агрегаты истории
  (суммарное время, счётчики Помодоро, вода за период) — SQL-агрегации в DAO
  (custom queries / `Expression.sum`), не вычисления в Dart по всем строкам. Дата сессии =
  дата старта (clarification), нормализуется до полуночи UTC. Seed системных активностей
  (12 шт., включая «Молитва») — в `MigrationStrategy.onCreate`.
- **Rationale**: агрегация в SQLite быстра на 10⁴ строках; seed в onCreate гарантирует
  работоспособность сразу после установки (FR-044).
- **Alternatives considered**: materialized-счётчики в отдельной таблице — преждевременная
  оптимизация.

## R6. Матрица переходов и координация Bloc-ов

- **Decision**: вся матрица прерываний — в `StartActionUseCase` (единственная точка);
  `PomodoroBloc` не знает про `ActionBloc` и наоборот — сигналы через состояния, которые
  слушает `RootBlocListener` (Вариант В из CLAUDE.md). Пауза Помодоро-активности → событие
  `ActionPaused` → Помодоро `interrupted` + отмена уведомления (clarification).
- **Rationale**: принципы III и V конституции; тестируется чистым unit-тестом UseCase.
- **Alternatives considered**: шина событий (EventBus) — скрытые связи; прямые вызовы
  Bloc→Bloc — запрещены конституцией.

## R7. HUD и контекстная иконка

- **Decision**: чистая функция-резолвер `HudContextResolver` в domain water/hud:
  входы (активные триггеры туалета, слоты еды по времени, расписание спорта/сна, статус
  Помодоро) → `HudContextType` по приоритету Туалет > Еда > Спорт > Сон > пусто. `HudCubit`
  комбинирует Stream-ы (вода, расписание, состояние Помодоро через RootBlocListener).
- **Rationale**: приоритет — инвариант конституции; чистая функция тривиально тестируется.
- **Alternatives considered**: логика в виджете — нетестируемо, размазывание инварианта.

## R8. Тестовая стратегия БД

- **Decision**: DAO-тесты на `NativeDatabase.memory()`; репозитории в bloc/unit-тестах
  мокаются mocktail. Добавить `bloc_test`, `mocktail` в dev_dependencies.
- **Rationale**: in-memory SQLite — штатный подход Drift, быстрые честные тесты миграций и
  custom queries.
- **Alternatives considered**: мок DAO повсюду — не проверяет SQL.

## R9. Отчёты и графики

- **Decision**: экран отчётов — на тех же DAO-агрегатах, что история; графики `fl_chart`
  (bar — время по дням, line/бар — вода). Экспорт файлов — вне MVP.
- **Rationale**: переиспользование запросов истории (FR-041 = пресеты периодов).
- **Alternatives considered**: отдельный слой аналитики — избыточен для MVP.

## R10. Тосты/снэкбары

- **Decision**: `toastification` (уже в pubspec) как реализация уведомлений UI
  («Помодоро прерван активностью X»), вызывается только из listener-ов (RootBlocListener /
  BlocListener), не из emit.
- **Rationale**: пакет уже выбран в проекте; правило side-effects конституции соблюдено.
- **Alternatives considered**: ScaffoldMessenger — допустим, но toastification уже подключён;
  оставить оба механизма — нет, один канал.
