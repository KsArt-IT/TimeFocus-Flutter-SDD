/// Type of a day schedule event.
enum ScheduleEventType {
  wakeUp,
  meal,
  work,
  sport,
  sleep,
  custom;

  factory ScheduleEventType.fromIndex(int index) =>
      ScheduleEventType.values.asMap()[index] ?? ScheduleEventType.custom;
}
