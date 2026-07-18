/// Status of a Pomodoro session interval.
enum PomodoroStatus {
  active,
  completed,
  interrupted,
  skipped;

  factory PomodoroStatus.fromIndex(int index) =>
      PomodoroStatus.values.asMap()[index] ?? PomodoroStatus.interrupted;
}
