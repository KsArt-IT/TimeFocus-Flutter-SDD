import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';

part 'session_edit_state.freezed.dart';

@freezed
sealed class SessionEditState with _$SessionEditState {
  const factory SessionEditState.loading() = SessionEditLoading;

  const factory SessionEditState.loaded({
    required HistorySessionEntity session,
    @Default(<ActionNameEntity>[]) List<ActionNameEntity> availableActions,

    /// The session's live running row (today only) — null means "stopped".
    RunningWithNameEntity? running,
  }) = SessionEditLoaded;

  /// The session (and its intervals) was deleted — the page should pop.
  const factory SessionEditState.deleted() = SessionEditDeleted;

  const factory SessionEditState.error(AppFailure failure) = SessionEditError;
}
