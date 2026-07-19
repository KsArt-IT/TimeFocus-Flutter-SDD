import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/features/notifications/domain/entities/notification_intent.dart';

part 'notification_state.freezed.dart';

@freezed
abstract class NotificationState with _$NotificationState {
  const factory NotificationState({NotificationIntent? pendingIntent}) = _NotificationState;
}
