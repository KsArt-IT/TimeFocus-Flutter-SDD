/// Drink type for water quick buttons (localization keys).
enum DrinkType {
  water,
  tea,
  coffee,
  milk,
  bottle;

  factory DrinkType.fromIndex(int index) => DrinkType.values.asMap()[index] ?? DrinkType.water;
}
