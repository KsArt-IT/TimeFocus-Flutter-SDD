/// Behaviour mode of an activity.
enum ActionMode {
  nothing,
  pomodoro,
  breakFor;

  factory ActionMode.fromIndex(int index) => ActionMode.values.asMap()[index] ?? ActionMode.nothing;
}
