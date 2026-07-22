import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// Canonical keys of seeded system activities. For system rows `ActionNames.name`
/// stores the key; UI translates it unless the user renamed the activity (FR-042).
enum SystemAction {
  sleep,
  meditation,
  prayer,
  work,
  breakFor,
  rest,
  walk,
  sport,
  meal,
  warmup,
  toilet,
  medicine,
  ;

  static SystemAction? fromName(String n) => SystemAction.values.asNameMap()[n];

  /// Activities that mute notifications while active (FR-037).
  static final muting = [sleep.name, meditation.name, prayer.name];

  /// HUD priority, declaration order relies on it (lowest first): sleep <
  /// work < rest < breakFor < walk < meditation < prayer < sport < meal <
  /// warmup < toilet < medicine (highest).
  int get priority => index;

  String label(AppLocalizations l10n) => switch (this) {
    work => l10n.systemActionWork,
    breakFor => l10n.systemActionBreak,
    rest => l10n.systemActionRest,
    sleep => l10n.systemActionSleep,
    toilet => l10n.systemActionToilet,
    meal => l10n.systemActionMeal,
    sport => l10n.systemActionSport,
    warmup => l10n.systemActionWarmup,
    walk => l10n.systemActionWalk,
    meditation => l10n.systemActionMeditation,
    prayer => l10n.systemActionPrayer,
    medicine => l10n.systemActionMedicine,
  };

  FaIconData get icon => switch (this) {
    work => FontAwesomeIcons.briefcase,
    breakFor => FontAwesomeIcons.couch,
    rest => FontAwesomeIcons.userSecret,
    sleep => FontAwesomeIcons.bed,
    toilet => FontAwesomeIcons.toilet,
    meal => FontAwesomeIcons.utensils,
    sport => FontAwesomeIcons.dumbbell,
    warmup => FontAwesomeIcons.personRays,
    walk => FontAwesomeIcons.personWalking,
    meditation => FontAwesomeIcons.spa,
    prayer => FontAwesomeIcons.handsPraying,
    medicine => FontAwesomeIcons.pills,
  };
}
