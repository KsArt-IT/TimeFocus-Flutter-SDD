import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/shared/enums/notification_type.dart';

part 'timeline_item.freezed.dart';

/// Source of a [TimelineItem] (FR-030): plan block, tracker interval, a
/// water log point, or a pending (not yet delivered) reminder.
enum TimelineItemKind { planned, actual, water, reminder }

/// A single row of the day timeline — SchedulePage lays these out on lanes
/// when they overlap in time (FR-030). Text is not localized here (domain
/// stays Flutter-free); widgets localize [event]/[actionName]/[reminderType].
@freezed
abstract class TimelineItem with _$TimelineItem {
  const TimelineItem._();

  const factory TimelineItem({
    required TimelineItemKind kind,
    required DateTime start,
    required int color,
    DateTime? end,
    ScheduleEventEntity? event,
    String? actionName,
    bool? isSystemAction,
    int? waterVolume,
    NotificationType? reminderType,
  }) = _TimelineItem;

  DateTime get effectiveEnd => end ?? start;
}
