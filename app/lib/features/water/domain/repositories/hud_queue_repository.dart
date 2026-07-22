import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/water/domain/entities/hud_queue_item_entity.dart';

/// Persistent queue of HUD system-action suggestions (contracts/blocs.md —
/// HudCubit). A `SystemAction` appears at most once; see `HudQueueItems`.
abstract interface class HudQueueRepository {
  Stream<List<HudQueueItemEntity>> watchActive(DateTime day);

  /// Raises [action] for [day] — inserts it, or refreshes (un-dismisses) it
  /// if it's already queued. For a genuinely new occasion (e.g. drank water
  /// again).
  Future<Result<void>> raise(SystemAction action, DateTime day);

  /// Raises [action] for [day] only if it isn't already queued — never
  /// revives a row the user already dismissed or started. For level-triggered
  /// checks (e.g. "has this schedule time passed?") that re-run on every
  /// tick/app restart and aren't a new occasion each time.
  Future<Result<void>> raiseIfNew(SystemAction action, DateTime day);

  Future<Result<void>> dismiss(int id);

  /// Drops rows left over from a previous day.
  Future<Result<void>> purgeStale(DateTime today);
}
