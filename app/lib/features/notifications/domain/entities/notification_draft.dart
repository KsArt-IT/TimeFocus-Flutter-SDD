import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/shared/enums/notification_type.dart';

part 'notification_draft.freezed.dart';

/// A notification to be scheduled. Payload must be self-sufficient for cold
/// start handling (contracts/notifications.md).
@freezed
abstract class NotificationDraft with _$NotificationDraft {
  const factory NotificationDraft({
    required NotificationType type,
    required DateTime scheduledAt,
    required String title,
    required String body,
    @Default(<String, Object?>{}) Map<String, Object?> payload,

    /// Localized label for the extendBreak action button (breakFinished
    /// only, T061) — built by the caller, which has l10n access.
    String? extendBreakLabel,
  }) = _NotificationDraft;
}
