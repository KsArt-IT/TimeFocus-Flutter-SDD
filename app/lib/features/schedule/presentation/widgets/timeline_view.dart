import 'package:flutter/material.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/features/schedule/domain/entities/timeline_item.dart';
import 'package:timefocus/features/schedule/presentation/widgets/timeline_item_tile.dart';
import 'package:timefocus/features/schedule/presentation/widgets/timeline_layout.dart';

/// Vertical 00:00–24:00 timeline; overlapping items are laid out on separate
/// lanes side by side (FR-030).
class TimelineView extends StatelessWidget {
  const TimelineView({required this.items, required this.onTap, super.key});

  final List<TimelineItem> items;
  final ValueChanged<TimelineItem> onTap;

  static const double _pixelsPerMinute = 1.4;
  static const double _hourLabelWidth = 48;
  static const double _minItemHeight = 28;

  @override
  Widget build(BuildContext context) {
    final layout = TimelineLayout(items);
    final (startHour, endHour) = _hourRange();
    final startOffsetMinutes = startHour * 60;
    final totalHeight = (endHour - startHour) * 60 * _pixelsPerMinute;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimens.bottomPaddingSmall),
      child: SizedBox(
        height: totalHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _hourLabelWidth,
              height: totalHeight,
              child: _HourLabels(startHour: startHour, endHour: endHour),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneWidth = constraints.maxWidth / layout.laneCount;
                  return Stack(
                    children: [
                      ..._hourGridLines(context, startHour, endHour, startOffsetMinutes),
                      for (final laned in layout.laned)
                        _positionedTile(laned, laneWidth, startOffsetMinutes),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full day when there are no items; otherwise the hour range spanning the
  /// earliest start to the latest end, so the grid has no dead space.
  (int, int) _hourRange() {
    if (items.isEmpty) return (0, 24);

    final minStart = items
        .map((item) => item.start.hour * 60 + item.start.minute)
        .reduce((a, b) => a < b ? a : b);
    final maxEnd = items
        .map((item) => item.effectiveEnd.hour * 60 + item.effectiveEnd.minute)
        .reduce((a, b) => a > b ? a : b);

    final startHour = minStart ~/ 60;
    final endHour = ((maxEnd + 59) ~/ 60).clamp(startHour + 1, 24);
    return (startHour, endHour);
  }

  Widget _positionedTile(LanedTimelineItem laned, double laneWidth, int startOffsetMinutes) {
    final startMinutes = laned.item.start.hour * 60 + laned.item.start.minute;
    final endMinutes = laned.item.effectiveEnd.hour * 60 + laned.item.effectiveEnd.minute;
    final height = ((endMinutes - startMinutes) * _pixelsPerMinute).clamp(
      _minItemHeight,
      double.infinity,
    );
    return Positioned(
      top: (startMinutes - startOffsetMinutes) * _pixelsPerMinute,
      left: laned.lane * laneWidth,
      width: laneWidth,
      height: height,
      child: TimelineItemTile(item: laned.item, onTap: () => onTap(laned.item)),
    );
  }

  List<Widget> _hourGridLines(
    BuildContext context,
    int startHour,
    int endHour,
    int startOffsetMinutes,
  ) {
    final color = Theme.of(context).dividerColor;
    return [
      for (var hour = startHour; hour < endHour; hour++)
        Positioned(
          top: (hour * 60 - startOffsetMinutes) * _pixelsPerMinute,
          left: 0,
          right: 0,
          child: Divider(height: 1, thickness: 0.5, color: color),
        ),
    ];
  }
}

class _HourLabels extends StatelessWidget {
  const _HourLabels({required this.startHour, required this.endHour});

  final int startHour;
  final int endHour;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    final startOffsetMinutes = startHour * 60;
    return Stack(
      children: [
        for (var hour = startHour; hour < endHour; hour++)
          Positioned(
            top: (hour * 60 - startOffsetMinutes) * TimelineView._pixelsPerMinute,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('${hour.toString().padLeft(2, '0')}:00', style: style),
            ),
          ),
      ],
    );
  }
}
