import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/gen/app_localizations.dart';

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

  String label(AppLocalizations l10n) => switch (this) {
    empty => '',
    sleep => l10n.scheduleEventSleep,
    sport => l10n.scheduleEventSport,
    meal => l10n.scheduleEventMeal,
    toilet => '',
  };

  FaIconData get icon => switch (this) {
    empty => FontAwesomeIcons.circle,
    sleep => FontAwesomeIcons.bed,
    sport => FontAwesomeIcons.personRunning,
    meal => FontAwesomeIcons.utensils,
    toilet => FontAwesomeIcons.toilet,
  };
}
