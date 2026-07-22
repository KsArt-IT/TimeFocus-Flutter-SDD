import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/features/water/domain/entities/hud_queue_item_entity.dart';
import 'package:timefocus/shared/database/app_database.dart';

extension HudQueueItemModelMapper on HudQueueItemModel {
  /// Null when [systemAction] no longer names a known `SystemAction`.
  HudQueueItemEntity? toEntity() {
    final action = SystemAction.fromName(systemAction);
    if (action == null) return null;
    return HudQueueItemEntity(id: id, action: action);
  }
}
