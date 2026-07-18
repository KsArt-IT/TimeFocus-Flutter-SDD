/// Status of a running activity.
enum ActionStatus {
  active,
  pause,
  stop;

  factory ActionStatus.fromIndex(int index) =>
      ActionStatus.values.asMap()[index] ?? ActionStatus.stop;
}
