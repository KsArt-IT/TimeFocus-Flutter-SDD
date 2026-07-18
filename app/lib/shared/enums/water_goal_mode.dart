/// How the daily water goal is calculated.
enum WaterGoalMode {
  weight,
  manual;

  factory WaterGoalMode.fromIndex(int index) =>
      WaterGoalMode.values.asMap()[index] ?? WaterGoalMode.manual;
}
