import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/icon_picker/fa_icon_name.dart';
import 'package:timefocus/shared/widgets/icon_picker/fa_icons_data.dart';

/// Categories for FontAwesome icons.
enum IconCategory {
  all,
  work,
  activities,
  sportsFitness,
  education,
  health,
  travel,
  buildings,
  food,
  nature,
  animals,
  technology,
  communication,
  gaming,
  religion,
  shopping,
  time,
  transportation,
  objects,
}

extension IconCategoryX on IconCategory {
  String categoryName(AppLocalizations l10n) => switch (this) {
    IconCategory.all => l10n.categoryAll,
    IconCategory.work => l10n.categoryWork,
    IconCategory.activities => l10n.categoryActivities,
    IconCategory.sportsFitness => l10n.categorySportsFitness,
    IconCategory.education => l10n.categoryEducation,
    IconCategory.health => l10n.categoryHealth,
    IconCategory.travel => l10n.categoryTravel,
    IconCategory.buildings => l10n.categoryBuildings,
    IconCategory.food => l10n.categoryFood,
    IconCategory.nature => l10n.categoryNature,
    IconCategory.animals => l10n.categoryAnimals,
    IconCategory.technology => l10n.categoryTechnology,
    IconCategory.communication => l10n.categoryCommunication,
    IconCategory.gaming => l10n.categoryGaming,
    IconCategory.religion => l10n.categoryReligion,
    IconCategory.shopping => l10n.categoryShopping,
    IconCategory.time => l10n.categoryTime,
    IconCategory.transportation => l10n.categoryTransportation,
    IconCategory.objects => l10n.categoryObjects,
  };

  List<FaIconName> categoryIcons(String search) => FaIconsData.search(search, category: this);
}
