import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/shared/enums/notification_type.dart';

part 'notification_entity.freezed.dart';

/// Mirror row of a scheduled notification.
@freezed
abstract class NotificationEntity with _$NotificationEntity {
  const factory NotificationEntity({
    required int id,
    required NotificationType type,
    required DateTime scheduledAt,
    required String payload,
    @Default(false) bool isDelivered,
  }) = _NotificationEntity;
}
