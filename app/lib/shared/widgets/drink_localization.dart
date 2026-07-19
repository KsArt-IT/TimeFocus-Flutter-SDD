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
