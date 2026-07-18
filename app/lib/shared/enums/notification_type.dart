/// Local notification types (contracts/notifications.md).
enum NotificationType {
  pomodoroFinished,
  breakFinished,
  mealFlexible,
  mealStrict,
  mealStrictWarning,
  waterReminder,
  toiletReminder,
  sleepReminder,
  extendBreak;

  factory NotificationType.fromIndex(int index) =>
      NotificationType.values.asMap()[index] ?? NotificationType.waterReminder;
}
