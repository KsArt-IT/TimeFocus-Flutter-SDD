import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/water/domain/entities/hud_queue_item_entity.dart';

/// Persistent queue of HUD system-action suggestions (contracts/blocs.md —
/// HudCubit). A `SystemAction` appears at most once; see `HudQueueItems`.
abstract interface class HudQueueRepository {
  Stream<List<HudQueueItemEntity>> watchActive(DateTime day);

  /// Raises [action] for [day] — inserts it, or refreshes (un-dismisses) it
  /// if it's already queued.
  Future<Result<void>> raise(SystemAction action, DateTime day);

  Future<Result<void>> dismiss(int id);

  /// Drops rows left over from a previous day.
  Future<Result<void>> purgeStale(DateTime today);
}
