import 'package:timefocus/features/history/domain/entities/history_interval_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/history/domain/entities/history_total_entity.dart';
import 'package:timefocus/shared/database/app_database.dart';
import 'package:timefocus/shared/database/daos/history_dao.dart';

extension IntervalWithActionMapper on IntervalWithAction {
  HistoryIntervalEntity toEntity() => HistoryIntervalEntity(
    intervalId: interval.id,
    historyId: interval.actionHistoryId,
    actionNameId: history.actionNameId,
    actionName: name.name,
    isSystemAction: name.isSystem,
    color: name.color,
    icon: name.icon,
    startedAt: interval.startedAt,
    finishedAt: interval.finishedAt,
  );
}

extension ActionTotalMapper on ActionTotal {
  HistoryTotalEntity toEntity() => HistoryTotalEntity(
    actionNameId: name.id,
    actionName: name.name,
    isSystemAction: name.isSystem,
    color: name.color,
    icon: name.icon,
    totalSec: totalSec,
    sessions: sessions,
  );
}

extension ActionHistoryIntervalModelMapper on ActionHistoryIntervalModel {
  HistoryIntervalEditEntity toEditEntity() =>
      HistoryIntervalEditEntity(id: id, startedAt: startedAt, finishedAt: finishedAt);
}

extension ActionHistorieModelMapper on ActionHistorieModel {
  HistorySessionEntity toEntity(List<ActionHistoryIntervalModel> intervals) => HistorySessionEntity(
    historyId: id,
    actionNameId: actionNameId,
    date: date,
    comment: comment,
    intervals: intervals.map((i) => i.toEditEntity()).toList(),
  );
}
