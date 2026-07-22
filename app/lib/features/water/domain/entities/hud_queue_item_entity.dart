import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/constants/system_actions.dart';

part 'hud_queue_item_entity.freezed.dart';

/// One suggestion in the HUD's persistent system-action queue.
@freezed
abstract class HudQueueItemEntity with _$HudQueueItemEntity {
  const factory HudQueueItemEntity({
    required int id,
    required SystemAction action,
  }) = _HudQueueItemEntity;
}
