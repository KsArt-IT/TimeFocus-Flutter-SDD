import 'package:timefocus/shared/enums/history_period.dart';

/// Single place turning (period, anchor) into a half-open [from, to) range
/// and stepping the anchor by one period (FR-038 navigation arrows).
(DateTime from, DateTime to) historyPeriodRange(HistoryPeriod period, DateTime anchor) {
  final day = DateTime(anchor.year, anchor.month, anchor.day);
  return switch (period) {
    .day => (day, day.add(const Duration(days: 1))),
    .week => _weekRange(day),
    .month => (
      DateTime(anchor.year, anchor.month),
      DateTime(anchor.year, anchor.month + 1),
    ),
    .year => (DateTime(anchor.year), DateTime(anchor.year + 1)),
  };
}

(DateTime, DateTime) _weekRange(DateTime day) {
  final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
  return (monday, monday.add(const Duration(days: 7)));
}

/// Moves [anchor] to the previous/next period (FR-038 navigation arrows).
DateTime historyStepAnchor(HistoryPeriod period, DateTime anchor, {required bool forward}) {
  final delta = forward ? 1 : -1;
  return switch (period) {
    .day => anchor.add(Duration(days: delta)),
    .week => anchor.add(Duration(days: 7 * delta)),
    .month => DateTime(anchor.year, anchor.month + delta, anchor.day),
    .year => DateTime(anchor.year + delta, anchor.month, anchor.day),
  };
}
