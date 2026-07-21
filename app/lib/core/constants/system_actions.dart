/// Canonical keys of seeded system activities. For system rows `ActionNames.name`
/// stores the key; UI translates it unless the user renamed the activity (FR-042).
enum SystemActionKeys {
  work,
  breakFor,
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
  ;

  static SystemActionKeys? fromName(String n) => SystemActionKeys.values.asNameMap()[n];

  /// Activities that mute notifications while active (FR-037).
  static final muting = [sleep.name, meditation.name, prayer.name];
}
