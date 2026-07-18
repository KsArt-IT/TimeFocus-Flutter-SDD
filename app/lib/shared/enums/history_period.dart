/// History aggregation period.
enum HistoryPeriod {
  day,
  week,
  month,
  year;

  factory HistoryPeriod.fromIndex(int index) =>
      HistoryPeriod.values.asMap()[index] ?? HistoryPeriod.day;
}
