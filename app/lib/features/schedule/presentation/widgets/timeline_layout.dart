import 'package:timefocus/features/schedule/domain/entities/timeline_item.dart';

/// A [TimelineItem] assigned to a lane so overlapping items render side by
/// side instead of on top of each other (FR-030).
class LanedTimelineItem {
  const LanedTimelineItem({required this.item, required this.lane});

  final TimelineItem item;
  final int lane;
}

/// Greedy lane assignment: items sorted by start; each goes into the first
/// lane whose last item already ended, otherwise a new lane opens.
class TimelineLayout {
  TimelineLayout(List<TimelineItem> items) {
    final sorted = [...items]..sort((a, b) => a.start.compareTo(b.start));
    final laneEnds = <DateTime>[];
    for (final item in sorted) {
      var lane = laneEnds.indexWhere((end) => !end.isAfter(item.start));
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(item.effectiveEnd);
      } else {
        laneEnds[lane] = item.effectiveEnd;
      }
      laned.add(LanedTimelineItem(item: item, lane: lane));
    }
    laneCount = laneEnds.isEmpty ? 1 : laneEnds.length;
  }

  final List<LanedTimelineItem> laned = [];
  late final int laneCount;
}
