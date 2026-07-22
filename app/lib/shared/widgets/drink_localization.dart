import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/drink_type.dart';

extension DrinkTypeL10n on DrinkType {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    DrinkType.water => l10n.drinkTypeWater,
    DrinkType.tea => l10n.drinkTypeTea,
    DrinkType.coffee => l10n.drinkTypeCoffee,
    DrinkType.milk => l10n.drinkTypeMilk,
    DrinkType.bottle => l10n.drinkTypeBottle,
  };
}

/// Quick-button names are stored as free text (WaterQuickButtons.label): a
/// preset matching a [DrinkType] name is translated, a user-entered custom
/// name is shown verbatim — same rule as `localizedActionName` (see
/// shared/widgets/action_localization.dart) for renamed system activities
/// (FR-042).
String localizedDrinkLabel(AppLocalizations l10n, String label) {
  final preset = DrinkType.values.asNameMap()[label];
  return preset?.localizedLabel(l10n) ?? label;
}
