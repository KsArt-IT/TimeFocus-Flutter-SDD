import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/data/datasources/local_notifications_datasource.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:timefocus/features/notifications/domain/usecases/notification_context_key.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

@LazySingleton(as: NotificationScheduler)
class NotificationSchedulerImpl with SafeCallMixin implements NotificationScheduler {
  NotificationSchedulerImpl(this._db, this._local);

  final AppDatabase _db;
  final LocalNotificationsDataSource _local;

  @override
  Future<Result<void>> schedule(NotificationDraft draft) => voidSafeCall(() async {
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
    );
  });

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
