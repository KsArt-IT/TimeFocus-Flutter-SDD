/// Canonical keys of seeded system activities. For system rows `ActionNames.name`
/// stores the key; UI translates it unless the user renamed the activity (FR-042).
abstract final class SystemActionKeys {
  static const String work = 'work';
  static const String breakKey = 'break';
  static const String rest = 'rest';
  static const String sleep = 'sleep';
  static const String toilet = 'toilet';
  static const String meal = 'meal';
  static const String sport = 'sport';
  static const String warmup = 'warmup';
  static const String walk = 'walk';
  static const String meditation = 'meditation';
  static const String prayer = 'prayer';
  static const String medicine = 'medicine';

  static const List<String> all = [
    work,
    breakKey,
    rest,
    sleep,
    toilet,
    meal,
    sport,
    warmup,
    walk,
    meditation,
    prayer,
    medicine,
  ];

  /// Activities that mute notifications while active (FR-037).
  static const List<String> muting = [sleep, meditation, prayer];
}
