/// What happens automatically after a Pomodoro work interval finishes.
enum PomodoroAfterAction {
  doNothing,
  autoStartBreak,
  suggestBreak,
  repeatSame,
  autoStartWork;

  factory PomodoroAfterAction.fromIndex(int index) =>
      PomodoroAfterAction.values.asMap()[index] ?? PomodoroAfterAction.doNothing;
}
