/// Schedule set: weekdays or weekend.
enum DayType {
  weekday,
  weekend;

  factory DayType.fromIndex(int index) => DayType.values.asMap()[index] ?? DayType.weekday;

  factory DayType.fromDate(DateTime date) =>
      date.weekday >= DateTime.saturday ? DayType.weekend : DayType.weekday;
}
