/// Contextual HUD icon type, ordered by priority (index == priority).
enum HudContextType {
  empty,
  sleep,
  sport,
  meal,
  toilet;

  factory HudContextType.fromIndex(int index) =>
      HudContextType.values.asMap()[index] ?? HudContextType.empty;

  /// HUD priority: toilet(4) > meal(3) > sport(2) > sleep(1) > empty(0).
  int get priority => index;
}
