import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_event.freezed.dart';

/// What just caused deferred notifications to become deliverable again
/// (FR-034a).
enum ScheduleRecalcTrigger { pomodoroEnded, muteEnded }

@freezed
sealed class NotificationEvent with _$NotificationEvent {
  /// App start: cold-start launch details + rescheduleAll (FR-035a).
  const factory NotificationEvent.initialized() = NotificationsInitialized;

  /// Warm tap (LocalNotificationsDataSource.taps) or a decoded cold-start
  /// launch payload — same handling path either way.
  const factory NotificationEvent.tapped({String? payload, String? actionId}) = NotificationTapped;

  /// Pomodoro ended or a muting activity stopped — flush the deferred queue.
  const factory NotificationEvent.scheduleRecalculated(ScheduleRecalcTrigger trigger) =
      ScheduleRecalculated;

  /// RootBlocListener consumed NotificationState.pendingIntent.
  const factory NotificationEvent.intentHandled() = NotificationIntentHandled;
}
