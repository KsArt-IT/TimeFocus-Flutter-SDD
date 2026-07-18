/// Water reminder scheduling mode.
enum WaterReminderMode {
  interval,
  scheduled;

  factory WaterReminderMode.fromIndex(int index) =>
      WaterReminderMode.values.asMap()[index] ?? WaterReminderMode.interval;
}
