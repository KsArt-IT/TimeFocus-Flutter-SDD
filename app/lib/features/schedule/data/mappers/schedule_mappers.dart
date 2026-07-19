import 'package:drift/drift.dart';

import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/meal_slot.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';

extension ScheduleEventModelMapper on ScheduleEventModel {
  ScheduleEventEntity toEntity(DayType resolvedDayType) => ScheduleEventEntity(
    id: id,
    type: ScheduleEventType.fromIndex(type),
    mealSubtype: mealSubtype == null ? null : MealSlot.fromIndex(mealSubtype!),
    timeMinutes: timeMinutes,
    durationMinutes: durationMinutes,
    isStrictly: isStrictly,
    warningMinutes: warningMinutes,
    actionId: actionId,
    isEnabled: isEnabled,
    sortOrder: sortOrder,
    dayType: resolvedDayType,
  );
}

extension ScheduleEventEntityMapper on ScheduleEventEntity {
  ScheduleEventsCompanion toCompanion({bool includeId = true}) => ScheduleEventsCompanion(
    id: includeId && id != 0 ? Value(id) : const Value.absent(),
    type: Value(type.index),
    mealSubtype: Value(mealSubtype?.index),
    timeMinutes: Value(timeMinutes),
    durationMinutes: Value(durationMinutes),
    isStrictly: Value(isStrictly),
    warningMinutes: Value(warningMinutes),
    actionId: Value(actionId),
    isEnabled: Value(isEnabled),
    sortOrder: Value(sortOrder),
    dayType: Value(dayType.index),
  );
}
