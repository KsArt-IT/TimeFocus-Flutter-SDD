import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/errors/safe_call_mixin.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_entity.dart';
import 'package:timefocus/features/notifications/domain/repositories/notification_repository.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl with SafeCallMixin implements NotificationRepository {
  NotificationRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<int>> insert(NotificationDraft d) => safeCall(() async {
    final id = await _db.notificationDao.nextId();
    final payloadJson = jsonEncode({
      'type': d.type.index,
      'title': d.title,
      'body': d.body,
      ...d.payload,
    });
    await _db.notificationDao.insertNotification(
      NotificationsCompanion.insert(
        id: Value(id),
        type: d.type.index,
        scheduledAt: d.scheduledAt,
        payload: payloadJson,
      ),
    );
    return id;
  });

  @override
  Future<Result<void>> delete(int id) =>
      voidSafeCall(() => _db.notificationDao.deleteNotification(id));

  @override
  Future<Result<void>> deleteByType(NotificationType t) => voidSafeCall(
    () => _db.notificationDao.deleteByType(t.index),
  );

  @override
  Future<Result<List<NotificationEntity>>> pending(DateTime after) => safeCall(() async {
    final rows = await _db.notificationDao.pendingAfter(after);
    return rows
        .map(
          (r) => NotificationEntity(
            id: r.id,
            type: NotificationType.fromIndex(r.type),
            scheduledAt: r.scheduledAt,
            payload: r.payload,
            isDelivered: r.isDelivered,
          ),
        )
        .toList();
  });

  @override
  Future<Result<void>> markDelivered(int id) =>
      voidSafeCall(() => _db.notificationDao.markDelivered(id));
}
