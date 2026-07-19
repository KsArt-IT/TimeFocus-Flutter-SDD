import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/features/schedule/domain/entities/timeline_item.dart';
import 'package:timefocus/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:timefocus/features/schedule/domain/usecases/plan_day_events_usecase.dart';
import 'package:timefocus/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/notification_type.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';
import 'package:timefocus/shared/widgets/schedule_event_localization.dart';

export 'package:timefocus/features/schedule/presentation/cubit/schedule_state.dart';

/// Screen-scoped cubit for the SchedulePage (contracts/blocs.md): timeline =
/// merge(plan, tracked intervals, water points); also (re)plans the day's
/// mealFlexible/mealStrict/sleepReminder notifications whenever the plan
/// changes. "Active reminders" as a fourth timeline layer (FR-030) needs
/// NotificationRepository.pending(), which US5/T057 has not implemented yet.
@injectable
class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._schedule, this._waterRepo, this._planDayEvents, this._scheduler)
    : super(const ScheduleState.initial());

  final ScheduleRepository _schedule;
  final WaterRepository _waterRepo;
  final PlanDayEventsUseCase _planDayEvents;
  final NotificationScheduler _scheduler;

  late DateTime _day;
  DayType _dayType = DayType.weekday;

  StreamSubscription<List<ScheduleEventEntity>>? _eventsSub;
  StreamSubscription<List<TimelineItem>>? _actualSub;
  StreamSubscription<List<({DateTime createdAt, int volume})>>? _waterSub;

  List<ScheduleEventEntity> _events = const [];
  List<TimelineItem> _actual = const [];
  List<TimelineItem> _water = const [];

  Future<void> subscribe() async {
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _dayType = DayType.fromDate(now);

    _eventsSub = _schedule.watchDay(_dayType).listen((events) {
      _events = events;
      _emit();
      unawaited(_planNotifications(events));
    }, onError: (Object e) => logger.e('schedule stream error', error: e));

    _actualSub = _schedule.watchActualIntervals(_day).listen((items) {
      _actual = items;
      _emit();
    }, onError: (Object e) => logger.e('schedule intervals stream error', error: e));

    _waterSub = _waterRepo.watchLogPoints(_day).listen((points) {
      _water = points
          .map(
            (p) => TimelineItem(
              kind: TimelineItemKind.water,
              start: p.createdAt,
              color: 0xFF4A6FA5,
              waterVolume: p.volume,
            ),
          )
          .toList();
      _emit();
    }, onError: (Object e) => logger.e('schedule water stream error', error: e));
  }

  Future<void> _planNotifications(List<ScheduleEventEntity> events) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final plans = _planDayEvents(events: events, day: _day);
    for (final plan in plans) {
      if (isClosed) return;
      switch (plan) {
        case MealFlexiblePlan(:final event, :final at):
          final name = event.displayName(l10n);
          await _scheduler.schedule(
            NotificationDraft(
              type: NotificationType.mealFlexible,
              scheduledAt: at,
              title: l10n.mealReminderFlexibleTitle,
              body: l10n.mealReminderFlexibleBody(name),
              payload: {'scheduleEventId': event.id, 'targetActionId': event.actionId},
            ),
          );
        case MealStrictPlan(:final event, :final at):
          final name = event.displayName(l10n);
          await _scheduler.schedule(
            NotificationDraft(
              type: NotificationType.mealStrict,
              scheduledAt: at,
              title: l10n.mealReminderStrictTitle(name),
              body: l10n.mealReminderStrictBody,
              payload: {'scheduleEventId': event.id, 'targetActionId': event.actionId},
            ),
          );
        case SleepReminderPlan(:final at, :final event):
          await _scheduler.schedule(
            NotificationDraft(
              type: NotificationType.sleepReminder,
              scheduledAt: at,
              title: l10n.sleepReminderTitle,
              body: l10n.sleepReminderBody(AppConstants.sleepReminderMinutes),
              payload: {'scheduleEventId': event.id},
            ),
          );
      }
    }
  }

  Future<void> createEvent(ScheduleEventEntity event) async {
    final result = await _schedule.create(event.copyWith(dayType: _dayType));
    if (result.isFailure) logger.e('failed to create schedule event', error: result.errorOrNull);
  }

  Future<void> updateEvent(ScheduleEventEntity event) async {
    final result = await _schedule.update(event);
    if (result.isFailure) logger.e('failed to update schedule event', error: result.errorOrNull);
  }

  Future<void> deleteEvent(int id) async {
    final result = await _schedule.delete(id);
    if (result.isFailure) logger.e('failed to delete schedule event', error: result.errorOrNull);
  }

  void _emit() {
    final items = [..._events.map(_toPlannedItem), ..._actual, ..._water]
      ..sort((a, b) => a.start.compareTo(b.start));
    emit(ScheduleState.loaded(timeline: items, dayType: _dayType));
  }

  TimelineItem _toPlannedItem(ScheduleEventEntity event) => TimelineItem(
    kind: TimelineItemKind.planned,
    start: _day.add(Duration(minutes: event.timeMinutes)),
    end: _day.add(Duration(minutes: event.timeMinutes + event.durationMinutes)),
    color: switch (event.type) {
      ScheduleEventType.wakeUp => 0xFF9B8AC4,
      ScheduleEventType.meal => 0xFFE0885A,
      ScheduleEventType.work => 0xFF4A6FA5,
      ScheduleEventType.sport => 0xFFD1495B,
      ScheduleEventType.sleep => 0xFF5C6BC0,
      ScheduleEventType.custom => 0xFF8D9CA3,
    },
    event: event,
  );

  @override
  Future<void> close() async {
    await _eventsSub?.cancel();
    await _actualSub?.cancel();
    await _waterSub?.cancel();
    return super.close();
  }
}
