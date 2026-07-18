import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_entity.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

/// DB mirror of the notification planner (FR-034a: at most one undelivered
/// notification per (type, context key)).
abstract interface class NotificationRepository {
  Future<Result<int>> insert(NotificationDraft d);

  Future<Result<void>> delete(int id);

  Future<Result<void>> deleteByType(NotificationType t);

  Future<Result<List<NotificationEntity>>> pending(DateTime after);

  Future<Result<void>> markDelivered(int id);
}
