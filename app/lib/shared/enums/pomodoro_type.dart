/// Pomodoro work interval length preset.
enum PomodoroType {
  short,
  normal,
  long;

  factory PomodoroType.fromIndex(int index) =>
      PomodoroType.values.asMap()[index] ?? PomodoroType.normal;
}
