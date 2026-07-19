import 'package:flutter/material.dart';

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
    final totalHeight = 24 * 60 * _pixelsPerMinute;

    return SingleChildScrollView(
      child: SizedBox(
        height: totalHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _hourLabelWidth,
              height: totalHeight,
              child: _HourLabels(totalHeight: totalHeight),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneWidth = constraints.maxWidth / layout.laneCount;
                  return Stack(
                    children: [
                      ..._hourGridLines(context, totalHeight),
                      for (final laned in layout.laned) _positionedTile(laned, laneWidth),
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

  Widget _positionedTile(LanedTimelineItem laned, double laneWidth) {
    final startMinutes = laned.item.start.hour * 60 + laned.item.start.minute;
    final endMinutes = laned.item.effectiveEnd.hour * 60 + laned.item.effectiveEnd.minute;
    final height = ((endMinutes - startMinutes) * _pixelsPerMinute).clamp(
      _minItemHeight,
      double.infinity,
    );
    return Positioned(
      top: startMinutes * _pixelsPerMinute,
      left: laned.lane * laneWidth,
      width: laneWidth,
      height: height,
      child: TimelineItemTile(item: laned.item, onTap: () => onTap(laned.item)),
    );
  }

  List<Widget> _hourGridLines(BuildContext context, double totalHeight) {
    final color = Theme.of(context).dividerColor;
    return [
      for (var hour = 0; hour < 24; hour++)
        Positioned(
          top: hour * 60 * _pixelsPerMinute,
          left: 0,
          right: 0,
          child: Divider(height: 1, thickness: 0.5, color: color),
        ),
    ];
  }
}

class _HourLabels extends StatelessWidget {
  const _HourLabels({required this.totalHeight});

  final double totalHeight;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Stack(
      children: [
        for (var hour = 0; hour < 24; hour++)
          Positioned(
            top: hour * 60 * TimelineView._pixelsPerMinute,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('${hour.toString().padLeft(2, '0')}:00', style: style),
            ),
          ),
      ],
    );
  }
}
