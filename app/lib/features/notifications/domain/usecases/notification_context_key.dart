import 'package:timefocus/shared/enums/notification_type.dart';

/// Deterministic dedupe key per (type, payload) — FR-034a: at most one
/// undelivered notification per (type, context key); a new one replaces it.
String notificationContextKey(NotificationType type, Map<String, Object?> payload) =>
    switch (type) {
      NotificationType.pomodoroFinished => 'action:${payload['actionId']}',
      NotificationType.breakFinished => 'action:${payload['parentActionId']}',
      NotificationType.extendBreak => 'action:${payload['breakActionId']}',
      NotificationType.mealFlexible ||
      NotificationType.mealStrict ||
      NotificationType.mealStrictWarning => 'event:${payload['scheduleEventId']}',
      NotificationType.sleepReminder => 'event:${payload['scheduleEventId']}',
      NotificationType.waterReminder || NotificationType.toiletReminder => 'type',
    };
