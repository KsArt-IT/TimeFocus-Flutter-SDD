import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_intent.freezed.dart';

/// What RootBlocListener must do after a notification tap (warm or cold
/// start — contracts/notifications.md, one path for both).
@freezed
sealed class NotificationIntent with _$NotificationIntent {
  /// Just bring the app to the tracker tab — no business-logic action
  /// (also FR-035: a stale/undecodable payload opens without acting).
  const factory NotificationIntent.openTracker() = OpenTrackerIntent;

  /// breakFinished: resume the parent work activity (source: system — does
  /// not count as an interruption).
  const factory NotificationIntent.resumeWork(int actionNameId) = ResumeWorkIntent;

  /// mealFlexible/mealStrict: start the linked activity — only on tap, never
  /// automatically (FR-031).
  const factory NotificationIntent.startAction(int actionNameId) = StartActionIntent;

  /// extendBreak action button on breakFinished.
  const factory NotificationIntent.extendBreak(int minutes) = ExtendBreakIntent;
}
