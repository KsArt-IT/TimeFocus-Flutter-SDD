import 'dart:async';
import 'dart:ui' show Locale;

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/water/domain/entities/day_schedule_times_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/features/water/domain/usecases/log_water_usecase.dart';
import 'package:timefocus/features/water/domain/usecases/plan_water_reminders_usecase.dart';
import 'package:timefocus/features/water/domain/usecases/resolve_hud_context_usecase.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_state.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/hud_context_type.dart';
import 'package:timefocus/shared/enums/notification_type.dart';
import 'package:timefocus/shared/enums/water_reminder_mode.dart';

export 'package:timefocus/features/water/presentation/cubit/hud_state.dart';

/// Global HUD cubit (contracts/blocs.md — HudCubit): water bar + contextual
/// icon, reactive on the water/settings/running streams. Never imports other
/// Blocs — coordination happens through RootBlocListener calling
/// [onPomodoroBreakStarted]/[onPomodoroStateChanged].
@lazySingleton
class HudCubit extends Cubit<HudState> {
  HudCubit(this._water, this._logWater, this._planReminders, this._scheduler)
    : super(const HudState.initial());

  final WaterRepository _water;
  final LogWaterUseCase _logWater;
  final PlanWaterRemindersUseCase _planReminders;
  final NotificationScheduler _scheduler;

  StreamSubscription<int>? _drankSub;
  StreamSubscription<WaterSettingsEntity>? _settingsSub;
  StreamSubscription<List<WaterQuickButtonEntity>>? _quickButtonsSub;
  StreamSubscription<int?>? _prioritySub;
  Timer? _ticker;

  int _currentMl = 0;
  int _goalMl = AppConstants.defaultDailyWaterGoalMl;
  WaterSettingsEntity _settings = const WaterSettingsEntity();
  List<WaterQuickButtonEntity> _quickButtons = const [];
  int? _activeRunningPriority;
  bool _pomodoroActive = false;
  bool _pomodoroBreakActive = false;
  DayScheduleTimesEntity _scheduleTimes = const DayScheduleTimesEntity();
  HudContextType? _dismissedContext;

  List<WaterQuickButtonEntity> get quickButtons => _quickButtons;

  Future<void> subscribe() async {
    final now = DateTime.now();
    final day = DateTime.utc(now.year, now.month, now.day);

    final goalResult = await _water.ensureDailyGoal(day);
    if (isClosed) return;
    _goalMl = goalResult.valueOrNull ?? AppConstants.defaultDailyWaterGoalMl;

    final timesResult = await _water.dayScheduleTimes(DayType.fromDate(now));
    if (isClosed) return;
    _scheduleTimes = timesResult.valueOrNull ?? const DayScheduleTimesEntity();

    _drankSub = _water.watchDrankToday(day).listen((ml) {
      _currentMl = ml;
      _recompute();
    }, onError: (Object e) => logger.e('water stream error', error: e));
    _settingsSub = _water.watchSettings().listen((s) {
      _settings = s;
      _recompute();
    }, onError: (Object e) => logger.e('water settings stream error', error: e));
    _quickButtonsSub = _water.watchQuickButtons().listen((buttons) {
      _quickButtons = buttons;
      _recompute();
    }, onError: (Object e) => logger.e('quick buttons stream error', error: e));
    _prioritySub = _water.watchActiveHudPriority().listen((p) {
      _activeRunningPriority = p;
      _recompute();
    }, onError: (Object e) => logger.e('hud priority stream error', error: e));
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _recompute());
    _recompute();
  }

  Future<void> logWater(int volume) async {
    final result = await _logWater(volume);
    if (isClosed || result.isFailure) return;
    await _afterLog();
  }

  Future<void> logDrink(int quickButtonId) async {
    final button = _quickButtons.firstWhereOrNull((b) => b.id == quickButtonId);
    if (button == null) return;
    await logWater(button.volume);
  }

  Future<void> _afterLog() async {
    final settingsResult = await _water.currentSettings();
    if (isClosed) return;
    final settings = settingsResult.valueOrNull;
    if (settings == null) return;
    _settings = settings;

    if (settings.reminderMode == WaterReminderMode.interval) {
      final plan = _planReminders(settings: settings, now: DateTime.now());
      await _scheduler.cancelByType(NotificationType.waterReminder);
      if (isClosed) return;
      if (plan is SingleWaterReminder) await _scheduleWaterReminder(plan.at);
      if (isClosed) return;
    }

    if (settings.showToiletOnWater) await _scheduleToiletReminder();
    if (isClosed) return;
    _recompute();
  }

  void onPomodoroBreakStarted() {
    _pomodoroBreakActive = true;
    if (_settings.showToiletOnBreak) unawaited(_scheduleToiletReminder());
    _recompute();
  }

  void onPomodoroStateChanged({required bool isActive}) {
    _pomodoroActive = isActive;
    _pomodoroBreakActive = false;
    _recompute();
  }

  void onToiletTapped() {
    _dismissedContext = HudContextType.toilet;
    _pomodoroBreakActive = false;
    unawaited(_scheduler.cancelByType(NotificationType.toiletReminder));
    _recompute();
  }

  void dismissContext() {
    final current = state;
    if (current is HudLoaded) _dismissedContext = current.context;
    _recompute();
  }

  Future<void> _scheduleWaterReminder(DateTime at) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final expectedAtReminder = expectedByNowMl(
      goalMl: _goalMl,
      nowMinutes: at.hour * 60 + at.minute,
      wakeUpMinutes: _scheduleTimes.wakeUpMinutes,
      sleepMinutes: _scheduleTimes.sleepMinutes,
    );
    final glasses = recommendedGlasses(currentMl: _currentMl, expectedByNowMl: expectedAtReminder);
    await _scheduler.schedule(
      NotificationDraft(
        type: NotificationType.waterReminder,
        scheduledAt: at,
        title: l10n.waterReminderTitle,
        body: l10n.waterReminderBody(
          _currentMl,
          _goalMl,
          l10n.waterRecommendGlasses(glasses),
        ),
        payload: {'currentMl': _currentMl, 'goalMl': _goalMl, 'recommendedGlasses': glasses},
      ),
    );
  }

  Future<void> _scheduleToiletReminder() async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await _scheduler.schedule(
      NotificationDraft(
        type: NotificationType.toiletReminder,
        scheduledAt: DateTime.now(),
        title: l10n.toiletReminderTitle,
        body: l10n.toiletReminderBody,
      ),
    );
  }

  void _recompute() {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final toiletSuggested = resolveToiletSuggested(
      showToiletOnWater: _settings.showToiletOnWater,
      showToiletOnBreak: _settings.showToiletOnBreak,
      lastDrankAt: _settings.lastDrankAt,
      pomodoroBreakActive: _pomodoroBreakActive,
      now: now,
    );
    final mealTimeNow = resolveMealTimeNow(nowMinutes, _scheduleTimes.mealTimesMinutes);
    var context = resolveHudContext(
      activeRunningPriority: _activeRunningPriority,
      toiletSuggested: toiletSuggested,
      mealTimeNow: mealTimeNow,
    );
    if (context == _dismissedContext) {
      context = HudContextType.empty;
    } else {
      _dismissedContext = null;
    }

    final expected = expectedByNowMl(
      goalMl: _goalMl,
      nowMinutes: nowMinutes,
      wakeUpMinutes: _scheduleTimes.wakeUpMinutes,
      sleepMinutes: _scheduleTimes.sleepMinutes,
    );

    emit(
      HudState.loaded(
        currentMl: _currentMl,
        goalMl: _goalMl,
        expectedByNowMl: expected,
        context: context,
        contextPulsing: context != HudContextType.empty,
        glassBlinking: _pomodoroActive,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _drankSub?.cancel();
    await _settingsSub?.cancel();
    await _quickButtonsSub?.cancel();
    await _prioritySub?.cancel();
    _ticker?.cancel();
    return super.close();
  }
}
