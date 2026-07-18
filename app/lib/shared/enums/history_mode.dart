/// History screen display mode.
enum HistoryMode {
  intervals,
  totals,
  stats;

  factory HistoryMode.fromIndex(int index) =>
      HistoryMode.values.asMap()[index] ?? HistoryMode.intervals;
}
