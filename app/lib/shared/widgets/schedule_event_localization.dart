import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/meal_slot.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';

/// Shared localization for schedule events — used by SchedulePage widgets
/// and by PomodoroBloc when building the mealStrictWarning notification.
extension ScheduleEventL10n on ScheduleEventEntity {
  String displayName(AppLocalizations l10n) {
    if (type == ScheduleEventType.meal && mealSubtype != null) {
      return mealSubtype!.localizedName(l10n);
    }
    return switch (type) {
      ScheduleEventType.wakeUp => l10n.scheduleEventWakeUp,
      ScheduleEventType.meal => l10n.scheduleEventMeal,
      ScheduleEventType.work => l10n.scheduleEventWork,
      ScheduleEventType.sport => l10n.scheduleEventSport,
      ScheduleEventType.sleep => l10n.scheduleEventSleep,
      ScheduleEventType.custom => l10n.scheduleEventCustom,
    };
  }
}

extension MealSlotL10n on MealSlot {
  String localizedName(AppLocalizations l10n) => switch (this) {
    MealSlot.breakfast => l10n.mealSlotBreakfast,
    MealSlot.lunch => l10n.mealSlotLunch,
    MealSlot.dinner => l10n.mealSlotDinner,
    MealSlot.snack => l10n.mealSlotSnack,
  };
}
