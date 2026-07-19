import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// System activity names are stored as keys and translated in UI; a renamed
/// activity keeps the user's name untranslated (FR-042).
extension ActionNameL10n on ActionNameEntity {
  String localizedName(AppLocalizations l10n) =>
      localizedActionName(l10n, name: name, isSystem: isSystem);
}

/// Same rule as [ActionNameL10n.localizedName], for call sites that only
/// carry the raw (name, isSystem) pair — e.g. History's joined DAO rows.
String localizedActionName(AppLocalizations l10n, {required String name, required bool isSystem}) {
  if (!isSystem) return name;
  return switch (name) {
    SystemActionKeys.work => l10n.systemActionWork,
    SystemActionKeys.breakKey => l10n.systemActionBreak,
    SystemActionKeys.rest => l10n.systemActionRest,
    SystemActionKeys.sleep => l10n.systemActionSleep,
    SystemActionKeys.toilet => l10n.systemActionToilet,
    SystemActionKeys.meal => l10n.systemActionMeal,
    SystemActionKeys.sport => l10n.systemActionSport,
    SystemActionKeys.warmup => l10n.systemActionWarmup,
    SystemActionKeys.walk => l10n.systemActionWalk,
    SystemActionKeys.meditation => l10n.systemActionMeditation,
    SystemActionKeys.prayer => l10n.systemActionPrayer,
    SystemActionKeys.medicine => l10n.systemActionMedicine,
    _ => name,
  };
}
