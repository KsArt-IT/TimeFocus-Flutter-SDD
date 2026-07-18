import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

/// Single scheduling point for all local notifications
/// (contracts/notifications.md). Writes the DB mirror + zonedSchedule.
abstract interface class NotificationScheduler {
  Future<Result<void>> schedule(NotificationDraft draft);

  Future<Result<void>> cancel(int id);

  Future<Result<void>> cancelByType(NotificationType type);

  /// Cold start / settings change: re-plans everything from the DB mirror.
  Future<Result<void>> rescheduleAll();
}
