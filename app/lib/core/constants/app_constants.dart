/// Application-wide business constants (single source of magic numbers).
abstract final class AppConstants {
  /// Default water portion for a single glass tap, ml.
  static const int defaultWaterPortionMl = 200;

  /// Water reminders are skipped within this window around meals, minutes.
  static const int mealWindowMinutes = 15;

  /// Sleep reminder fires this many minutes before scheduled sleep.
  static const int sleepReminderMinutes = 30;

  /// Default action grid size.
  static const int defaultGridColumns = 4;
  static const int defaultGridRows = 5;

  /// Grid size limits (FR-009).
  static const int minGridSize = 1;
  static const int maxGridSize = 5;

  /// Height of one action grid tile (icon + label), dp.
  static const double actionItemHeight = 88;

  /// Daily water goal per body weight, ml per kg.
  static const int waterMlPerKg = 30;

  /// Default manual daily water goal, ml.
  static const int defaultDailyWaterGoalMl = 2000;

  /// Default water reminder interval, minutes.
  static const int defaultWaterReminderIntervalMin = 90;

  /// Break extension step for the extendBreak notification action, minutes.
  static const int extendBreakMinutes = 5;

  /// Maximum glasses recommended in a water reminder (FR-026).
  static const int maxRecommendedGlasses = 4;

  /// Pomodoro defaults, seconds.
  static const int pomodoroShortWorkSec = 900;
  static const int pomodoroNormalWorkSec = 1500;
  static const int pomodoroLongWorkSec = 2700;
  static const int pomodoroShortBreakSec = 300;
  static const int pomodoroLongBreakSec = 900;

  /// Pomodoro cycles before a long break (allowed range 3–5).
  static const int defaultCyclesBeforeLongBreak = 4;
  static const int minCyclesBeforeLongBreak = 3;
  static const int maxCyclesBeforeLongBreak = 5;

  /// Minimum tap target size for accessibility (FR-047), dp.
  static const double minTapTargetDp = 48;

  /// Quick adjust steps on the interval edit screen, minutes.
  static const List<int> intervalQuickAdjustMinutes = [-5, -1, 1, 5];

  /// Default schedule event duration, minutes.
  static const int defaultScheduleEventDurationMin = 30;
}
