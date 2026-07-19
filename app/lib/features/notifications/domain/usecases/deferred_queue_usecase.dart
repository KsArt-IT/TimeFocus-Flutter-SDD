import 'package:injectable/injectable.dart';

import 'package:timefocus/features/notifications/domain/entities/notification_draft.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

/// Types deferred while a Pomodoro (work or break) session is active
/// (contracts/notifications.md — "Откладывается" column).
const pomodoroDeferredTypes = {
  NotificationType.mealFlexible,
  NotificationType.waterReminder,
  NotificationType.sleepReminder,
};

/// FR-034a/FR-037: muted (Sleep/Meditation/Prayer running, or the global
/// notificationsEnabled flag off) defers everything; an active Pomodoro
/// only defers [pomodoroDeferredTypes].
bool shouldDeferNotification(
  NotificationType type, {
  required bool pomodoroActive,
  required bool muted,
}) => muted || (pomodoroActive && pomodoroDeferredTypes.contains(type));

/// Holds notifications that [shouldDeferNotification] postponed, to be
/// delivered in order once the Pomodoro ends or the mute lifts (FR-034a).
/// Owned by NotificationSchedulerImpl — the single scheduling point
/// (contracts/notifications.md) — so no caller needs to know about deferral.
@lazySingleton
class DeferredQueueUseCase {
  final List<NotificationDraft> _queue = [];

  bool get isEmpty => _queue.isEmpty;

  bool shouldDefer(NotificationType type, {required bool pomodoroActive, required bool muted}) =>
      shouldDeferNotification(type, pomodoroActive: pomodoroActive, muted: muted);

  void enqueue(NotificationDraft draft) => _queue.add(draft);

  /// Removes and returns everything queued, oldest first.
  List<NotificationDraft> drain() {
    final items = List<NotificationDraft>.of(_queue);
    _queue.clear();
    return items;
  }
}
