import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/data/datasources/local_notifications_datasource.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/notifications/domain/usecases/deferred_queue_usecase.dart';
import 'package:timefocus/features/notifications/domain/usecases/notification_context_key.dart';
import 'package:timefocus/features/pomodoro/domain/repositories/pomodoro_repository.dart';
import 'package:timefocus/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_running_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/action_status.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

@LazySingleton(as: NotificationScheduler)
class NotificationSchedulerImpl with SafeCallMixin implements NotificationScheduler {
  NotificationSchedulerImpl(
    this._db,
    this._local,
    this._deferred,
    this._runnings,
    this._pomodoro,
    this._userSettings,
  );

  final AppDatabase _db;
  final LocalNotificationsDataSource _local;
  final DeferredQueueUseCase _deferred;
  final ActionRunningRepository _runnings;
  final PomodoroRepository _pomodoro;
  final UserSettingsRepository _userSettings;

  @override
  Future<Result<void>> schedule(NotificationDraft draft) => voidSafeCall(() async {
    final muted = await _isMuted();
    final pomodoroActive = await _isPomodoroActive();
    if (_deferred.shouldDefer(draft.type, pomodoroActive: pomodoroActive, muted: muted)) {
      _deferred.enqueue(draft);
      return;
    }
    await _doSchedule(draft);
  });

  Future<void> _doSchedule(NotificationDraft draft) async {
    // FR-034a dedupe: replace an undelivered notification of the same
    // (type, context key).
    final key = notificationContextKey(draft.type, draft.payload);
    final undelivered = await _db.notificationDao.undeliveredOfType(draft.type.index);
    for (final n in undelivered) {
      final existingPayload = _decodePayload(n.payload);
      if (notificationContextKey(draft.type, existingPayload) == key) {
        await _local.cancel(n.id);
        await _db.notificationDao.deleteNotification(n.id);
      }
    }

    final id = await _db.notificationDao.nextId();
    // title/body are stored alongside the payload so rescheduleAll can
    // re-plan from the mirror alone.
    final payloadJson = jsonEncode({
      'type': draft.type.index,
      'title': draft.title,
      'body': draft.body,
      if (draft.extendBreakLabel != null) 'extendBreakLabel': draft.extendBreakLabel,
      ...draft.payload,
    });
    await _db.notificationDao.insertNotification(
      NotificationsCompanion.insert(
        id: Value(id),
        type: draft.type.index,
        scheduledAt: draft.scheduledAt,
        payload: payloadJson,
      ),
    );
    await _local.zonedSchedule(
      id: id,
      title: draft.title,
      body: draft.body,
      scheduledAt: draft.scheduledAt,
      payload: payloadJson,
      extendBreakLabel: draft.extendBreakLabel,
    );
  }

  Future<bool> _isMuted() async {
    final settingsResult = await _userSettings.get();
    if (settingsResult.valueOrNull?.notificationsEnabled == false) return true;
    final runningResult = await _runnings.currentRunning();
    final running = runningResult.valueOrNull ?? const [];
    return running.any(
      (r) => r.status == ActionStatus.active && SystemActionKeys.muting.contains(r.action.name),
    );
  }

  Future<bool> _isPomodoroActive() async {
    final result = await _pomodoro.activeSession();
    return result.valueOrNull != null;
  }

  @override
  Future<Result<void>> cancel(int id) => voidSafeCall(() async {
    await _local.cancel(id);
    await _db.notificationDao.deleteNotification(id);
  });

  @override
  Future<Result<void>> cancelByType(NotificationType type) => voidSafeCall(() async {
    final rows = await _db.notificationDao.undeliveredOfType(type.index);
    for (final n in rows) {
      await _local.cancel(n.id);
    }
    await _db.notificationDao.deleteByType(type.index);
  });

  @override
  Future<Result<void>> rescheduleAll() => voidSafeCall(() async {
    await _local.cancelAll();
    final now = DateTime.now();
    final pending = await _db.notificationDao.pendingAfter(now);
    for (final n in pending) {
      final payload = _decodePayload(n.payload);
      await _local.zonedSchedule(
        id: n.id,
        title: payload['title'] as String? ?? '',
        body: payload['body'] as String? ?? '',
        scheduledAt: n.scheduledAt,
        payload: n.payload,
        extendBreakLabel: payload['extendBreakLabel'] as String?,
      );
    }
  });

  @override
  Future<Result<void>> flushDeferred() => voidSafeCall(() async {
    final drafts = _deferred.drain();
    for (final (index, draft) in drafts.indexed) {
      await _doSchedule(
        draft.copyWith(scheduledAt: DateTime.now().add(Duration(seconds: 3 * index))),
      );
    }
  });

  Map<String, Object?> _decodePayload(String json) {
    try {
      return (jsonDecode(json) as Map<String, dynamic>).cast<String, Object?>();
    } on FormatException {
      return const {};
    }
  }
}
