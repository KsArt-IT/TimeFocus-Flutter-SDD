/// History screen display mode.
enum HistoryMode {
  intervals,
  water,
  totals,
  stats,
  ;

  factory HistoryMode.fromIndex(int index) =>
      HistoryMode.values.asMap()[index] ?? HistoryMode.intervals;
}
