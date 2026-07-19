import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A simple per-day bar chart for the Reports screen (FR-041).
class DailyBarChart extends StatelessWidget {
  const DailyBarChart({
    required this.title,
    required this.from,
    required this.to,
    required this.valuesByDay,
    required this.barColor,
    required this.valueLabel,
    super.key,
  });

  final String title;
  final DateTime from;
  final DateTime to;
  final Map<DateTime, int> valuesByDay;
  final Color barColor;
  final String Function(int value) valueLabel;

  List<DateTime> get _days {
    final days = <DateTime>[];
    var day = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    while (day.isBefore(end)) {
      days.add(day);
      day = day.add(const Duration(days: 1));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _days;
    final values = days.map((d) => valuesByDay[d] ?? 0).toList();
    final maxValue = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: maxValue <= 0
              ? Center(child: Text('—', style: theme.textTheme.bodyMedium))
              : BarChart(
                  BarChartData(
                    maxY: maxValue.toDouble() * 1.2,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                            BarTooltipItem(valueLabel(rod.toY.round()), theme.textTheme.bodySmall!),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= days.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${days[index].day}', style: theme.textTheme.labelSmall),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: [
                      for (final (index, value) in values.indexed)
                        BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(toY: value.toDouble(), color: barColor, width: 12),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
