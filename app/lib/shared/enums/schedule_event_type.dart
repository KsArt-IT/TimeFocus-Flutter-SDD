import 'package:timefocus/core/constants/system_actions.dart';

/// Type of a day schedule event. Persisted in the DB by name
/// (`schedule_events.type`), not index — free to reorder.
enum ScheduleEventType {
  custom,
  prayer,
  medicine,
  meal,
  work,
  sport,
  warmup,
  breakFor,
  rest,
  walk,
  meditation,
  wakeUp,
  sleep,
  ;

  static ScheduleEventType fromName(String n) =>
      ScheduleEventType.values.asNameMap()[n] ?? ScheduleEventType.custom;

  /// The system action this event type represents, or null for `wakeUp`/`custom`.
  SystemAction? get systemAction => SystemAction.fromName(name);
}
