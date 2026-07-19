import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_edit.dart';
import 'package:timefocus/features/history/domain/repositories/history_repository.dart';
import 'package:timefocus/features/history/presentation/cubit/session_edit_state.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';

export 'package:timefocus/features/history/presentation/cubit/session_edit_state.dart';

/// Screen-scoped cubit for SessionEditPage/IntervalEditPage (FR-040):
/// change activity/comment, add/edit/delete intervals, delete the session.
@injectable
class SessionEditCubit extends Cubit<SessionEditState> {
  SessionEditCubit(this._history, this._actions) : super(const SessionEditState.loading());

  final HistoryRepository _history;
  final ActionNameRepository _actions;

  Future<void> load(int historyId) async {
    final sessionResult = await _history.session(historyId);
    if (isClosed) return;
    final session = sessionResult.valueOrNull;
    if (session == null) {
      emit(SessionEditState.error(sessionResult.errorOrNull!));
      return;
    }
    final actions = await _actions.watchGrid().first;
    if (isClosed) return;
    emit(SessionEditState.loaded(session: session, availableActions: actions));
  }

  /// Applies the activity change and reloads, unless the session's day
  /// already has a separate session for [actionNameId] — ActionHistories' unique
  /// (actionNameId, date) key means that case can't be a plain update. When
  /// that happens nothing is changed yet; this returns the *other*
  /// session's id so the caller can confirm a merge via [confirmMerge].
  Future<int?> changeActivity(int actionNameId) async {
    final current = state;
    if (current is! SessionEditLoaded) return null;
    if (actionNameId == current.session.actionNameId) return null;

    final conflictResult = await _history.findConflictingSession(
      actionNameId: actionNameId,
      date: current.session.date,
      excludingHistoryId: current.session.historyId,
    );
    if (isClosed) return null;
    if (conflictResult.isFailure) {
      logger.e('failed to check for a conflicting session', error: conflictResult.errorOrNull);
      return null;
    }
    final conflictId = conflictResult.valueOrNull;
    if (conflictId != null) return conflictId;

    final result = await _history.updateSession(
      historyId: current.session.historyId,
      newActionNameId: actionNameId,
    );
    if (isClosed) return null;
    if (result.isFailure) {
      logger.e('failed to change session activity', error: result.errorOrNull);
      return null;
    }
    await load(current.session.historyId);
    return null;
  }

  /// User confirmed merging this session into [intoHistoryId] (FR-040 edge
  /// case: the target activity already had a session on this day).
  Future<void> confirmMerge(int intoHistoryId) async {
    final current = state;
    if (current is! SessionEditLoaded) return;
    final result = await _history.mergeSessions(
      fromHistoryId: current.session.historyId,
      intoHistoryId: intoHistoryId,
    );
    if (isClosed) return;
    if (result.isFailure) {
      logger.e('failed to merge sessions', error: result.errorOrNull);
      return;
    }
    await load(intoHistoryId);
  }

  Future<void> saveComment(String comment) async {
    final current = state;
    if (current is! SessionEditLoaded) return;
    final result = await _history.updateSession(
      historyId: current.session.historyId,
      comment: comment,
    );
    if (isClosed) return;
    if (result.isFailure) {
      logger.e('failed to save comment', error: result.errorOrNull);
      return;
    }
    await load(current.session.historyId);
  }

  /// Returns the overlap check so the caller can show a warning; reloads
  /// the session either way.
  Future<OverlapCheck?> saveInterval(HistoryIntervalEdit edit) async {
    final result = await _history.saveInterval(edit);
    if (isClosed) return null;
    if (result.isFailure) {
      logger.e('failed to save interval', error: result.errorOrNull);
      return null;
    }
    await load(edit.historyId);
    return result.valueOrNull;
  }

  Future<void> deleteInterval(int intervalId) async {
    final current = state;
    if (current is! SessionEditLoaded) return;
    final result = await _history.deleteInterval(intervalId);
    if (isClosed) return;
    if (result.isFailure) {
      logger.e('failed to delete interval', error: result.errorOrNull);
      return;
    }
    await load(current.session.historyId);
  }

  Future<void> deleteSession() async {
    final current = state;
    if (current is! SessionEditLoaded) return;
    final result = await _history.deleteSession(current.session.historyId);
    if (isClosed) return;
    if (result.isFailure) {
      logger.e('failed to delete session', error: result.errorOrNull);
      return;
    }
    emit(const SessionEditState.deleted());
  }
}
