import 'dart:convert';

import 'package:injectable/injectable.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/features/notifications/domain/entities/notification_intent.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

/// Action button id used on the breakFinished notification (Android/iOS
/// notification actions, T061).
const extendBreakActionId = 'extendBreak';

/// Single place turning a tapped notification's payload into an intent for
/// all 9 types (contracts/notifications.md). Pure: payload JSON in, intent
/// out — no I/O, so it works identically warm or from a cold start.
@injectable
class HandleNotificationTapUseCase {
  NotificationIntent call({String? payloadJson, String? actionId}) {
    if (actionId == extendBreakActionId) {
      return const NotificationIntent.extendBreak(AppConstants.extendBreakMinutes);
    }
    if (payloadJson == null) return const NotificationIntent.openTracker();

    final Map<String, Object?> payload;
    try {
      payload = (jsonDecode(payloadJson) as Map<String, dynamic>).cast<String, Object?>();
    } on FormatException {
      // FR-035: an unparsable/stale payload opens the app without acting.
      return const NotificationIntent.openTracker();
    }

    final typeIndex = payload['type'];
    if (typeIndex is! int) return const NotificationIntent.openTracker();
    final type = NotificationType.fromIndex(typeIndex);

    return switch (type) {
      NotificationType.breakFinished => _intOrOpenTracker(
        payload['parentActionId'],
        NotificationIntent.resumeWork,
      ),
      NotificationType.mealFlexible || NotificationType.mealStrict => _intOrOpenTracker(
        payload['targetActionId'],
        NotificationIntent.startAction,
      ),
      NotificationType.pomodoroFinished ||
      NotificationType.mealStrictWarning ||
      NotificationType.waterReminder ||
      NotificationType.toiletReminder ||
      NotificationType.sleepReminder ||
      NotificationType.extendBreak => const NotificationIntent.openTracker(),
    };
  }

  NotificationIntent _intOrOpenTracker(Object? value, NotificationIntent Function(int) build) =>
      value is int ? build(value) : const NotificationIntent.openTracker();
}
