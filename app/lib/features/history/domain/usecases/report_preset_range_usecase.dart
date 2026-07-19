/// The 7 slices FR-041 requires the Reports screen to offer.
enum ReportPreset { today, yesterday, thisWeek, lastWeek, thisMonth, lastMonth, last30Days }

/// Single place turning a [ReportPreset] into a half-open [from, to) range,
/// anchored on [now] (FR-041).
(DateTime from, DateTime to) reportPresetRange(ReportPreset preset, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (preset) {
    case ReportPreset.today:
      return (today, today.add(const Duration(days: 1)));
    case ReportPreset.yesterday:
      final yesterday = today.subtract(const Duration(days: 1));
      return (yesterday, today);
    case ReportPreset.thisWeek:
      final monday = today.subtract(Duration(days: today.weekday - DateTime.monday));
      return (monday, monday.add(const Duration(days: 7)));
    case ReportPreset.lastWeek:
      final thisMonday = today.subtract(Duration(days: today.weekday - DateTime.monday));
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      return (lastMonday, thisMonday);
    case ReportPreset.thisMonth:
      return (DateTime(today.year, today.month), DateTime(today.year, today.month + 1));
    case ReportPreset.lastMonth:
      return (DateTime(today.year, today.month - 1), DateTime(today.year, today.month));
    case ReportPreset.last30Days:
      return (today.subtract(const Duration(days: 29)), today.add(const Duration(days: 1)));
  }
}
