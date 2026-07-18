/// Meal subtype for schedule events of type meal.
enum MealSlot {
  breakfast,
  lunch,
  dinner,
  snack;

  factory MealSlot.fromIndex(int index) => MealSlot.values.asMap()[index] ?? MealSlot.snack;
}
