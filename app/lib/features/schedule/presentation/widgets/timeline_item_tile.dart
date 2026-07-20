import 'package:flutter/material.dart';

import 'package:timefocus/features/schedule/domain/entities/timeline_item.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/notification_type.dart';
import 'package:timefocus/shared/widgets/schedule_event_localization.dart';

/// Renders one [TimelineItem] box; kind decides icon/label/opacity so plan
/// and fact are visually distinct without relying on color alone (FR-047).
class TimelineItemTile extends StatelessWidget {
  const TimelineItemTile({required this.item, required this.onTap, super.key});

  final TimelineItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Color(item.color);
    final (icon, label) = switch (item.kind) {
      TimelineItemKind.planned => (
        item.event!.isStrictly ? Icons.lock_clock : Icons.event_outlined,
        item.event!.displayName(l10n),
      ),
      TimelineItemKind.actual => (Icons.play_circle_outline, item.actionName ?? ''),
      TimelineItemKind.water => (
        Icons.water_drop,
        l10n.drinkVolumeMl(item.waterVolume ?? 0),
      ),
      TimelineItemKind.reminder => (
        Icons.notifications_active_outlined,
        _reminderLabel(l10n, item.reminderType),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Material(
        color: color.withValues(alpha: item.kind == TimelineItemKind.actual ? 0.9 : 0.35),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Semantics(
            button: true,
            label: label,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Icon(icon, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _reminderLabel(AppLocalizations l10n, NotificationType? type) => switch (type) {
    NotificationType.mealFlexible ||
    NotificationType.mealStrict ||
    NotificationType.mealStrictWarning => l10n.scheduleEventMeal,
    NotificationType.sleepReminder => l10n.scheduleEventSleep,
    NotificationType.waterReminder => l10n.waterReminderTitle,
    NotificationType.toiletReminder => l10n.toiletReminderTitle,
    NotificationType.pomodoroFinished ||
    NotificationType.breakFinished ||
    NotificationType.extendBreak ||
    null => l10n.scheduleEventCustom,
  };
}
