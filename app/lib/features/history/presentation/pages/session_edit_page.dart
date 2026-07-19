import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/core/router/app_router.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/history/presentation/cubit/session_edit_cubit.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/entities/running_with_name_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/action_status.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/activity_picker_dialog.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';
import 'package:timefocus/shared/widgets/ticking_timer.dart';

/// FR-040: change the session's activity/comment, edit/add/delete its
/// intervals, or delete the whole session (cascade).
class SessionEditPage extends StatelessWidget {
  const SessionEditPage({required this.historyId, super.key});

  final int historyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionEditCubit>(
      create: (_) {
        final cubit = getIt<SessionEditCubit>();
        unawaited(cubit.load(historyId));
        return cubit;
      },
      child: const _SessionEditContent(),
    );
  }
}

class _SessionEditContent extends StatefulWidget {
  const _SessionEditContent();

  @override
  State<_SessionEditContent> createState() => _SessionEditContentState();
}

class _SessionEditContentState extends State<_SessionEditContent> {
  final _commentController = TextEditingController();

  /// Staged, not-yet-applied pick from ActivityPickerDialog — null means
  /// "unchanged" (still the loaded session's own activity).
  int? _draftActionId;
  int? _syncedForHistoryId;

  /// Staged running-status pick — null means "unchanged" (still whatever
  /// [SessionEditLoaded.running] says). Kept purely client-side, exactly
  /// like [_draftActionId]/[_commentController]: toggling the segmented
  /// control back and forth never touches the database, so flipping
  /// stopped→active→stopped without saving never leaves an interval behind
  /// — there's simply nothing to undo. [_draftStatusAt] is the moment the
  /// user picked [_draftStatus], used as the transition's real timestamp on
  /// Save (not whenever Save happens to be pressed).
  ActionStatus? _draftStatus;
  DateTime? _draftStatusAt;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Re-syncs the draft fields whenever a *different* session is loaded
  /// (first load, or after a merge changes the effective historyId) — but
  /// not on every rebuild, so in-progress edits survive unrelated state
  /// changes.
  void _syncDraft(HistorySessionEntity session) {
    if (_syncedForHistoryId == session.historyId) return;
    _syncedForHistoryId = session.historyId;
    _draftActionId = null;
    _commentController.text = session.comment ?? '';
    _draftStatus = null;
    _draftStatusAt = null;
  }

  /// The picked status is always relative to the *loaded* running row, not
  /// to any earlier pick this session — so selecting the original status
  /// again simply clears the draft instead of chaining through it.
  void _onRunningStatusChanged(ActionStatus target, RunningWithNameEntity? original) {
    final originalStatus = original?.status ?? ActionStatus.stop;
    setState(() {
      if (target == originalStatus) {
        _draftStatus = null;
        _draftStatusAt = null;
      } else {
        _draftStatus = target;
        _draftStatusAt = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<SessionEditCubit, SessionEditState>(
      listenWhen: (previous, current) => current is SessionEditDeleted,
      listener: (context, state) => context.pop(),
      builder: (context, state) {
        if (state is SessionEditLoaded) _syncDraft(state.session);
        final hasChanges = state is SessionEditLoaded && _hasChanges(state.session);

        return Scaffold(
          appBar: AppBar(
            title: state is SessionEditLoaded
                ? Column(
                    mainAxisSize: .min,
                    children: [
                      Text(l10n.sessionEditTitle),
                      Text(
                        DateFormat.yMMMMd(l10n.localeName).format(state.session.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : Text(l10n.sessionEditTitle),
            actions: [
              if (state is SessionEditLoaded) ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () => _confirmDeleteSession(context),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: l10n.save,
                  onPressed: hasChanges ? () => _save(context, state.session) : null,
                ),
              ],
            ],
          ),
          body: switch (state) {
            SessionEditLoading() => const Center(child: CircularProgressIndicator()),
            SessionEditDeleted() => const SizedBox.shrink(),
            SessionEditError(:final failure) => Center(child: Text(failure.localizedMessage(l10n))),
            SessionEditLoaded(:final session, :final availableActions, :final running) => ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                _ActivityRow(
                  currentActionId: _draftActionId ?? session.actionNameId,
                  availableActions: availableActions,
                  onPick: (picked) => setState(() => _draftActionId = picked.id),
                ),
                if (DateUtils.isSameDay(session.date, DateTime.now()))
                  _RunningStatusRow(
                    running: running,
                    draftStatus: _draftStatus,
                    draftStatusAt: _draftStatusAt,
                    onChanged: (status) => _onRunningStatusChanged(status, running),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _commentController,
                    decoration: InputDecoration(labelText: l10n.sessionComment),
                    onChanged: (_) => setState(() {}),
                    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
                const Divider(),
                for (final interval in session.intervals)
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text('${_hm(interval.startedAt)} – ${_hm(interval.finishedAt)}'),
                    trailing: Text(
                      formatDuration(interval.finishedAt.difference(interval.startedAt).inSeconds),
                    ),
                    onTap: () => _editInterval(context, session.historyId, interval.id),
                  ),
              ],
            ),
          },
          floatingActionButton: state is SessionEditLoaded
              ? FloatingActionButton(
                  tooltip: l10n.addInterval,
                  onPressed: () => _editInterval(context, state.session.historyId, null),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  /// Pushes the interval-edit route (a standalone screen with its own
  /// cubit, see IntervalEditPage) and reloads this session once it returns
  /// — that other cubit instance already saved/deleted for real, this one
  /// just needs to catch up.
  void _editInterval(BuildContext context, int historyId, int? intervalId) {
    final cubit = context.read<SessionEditCubit>();
    final query = intervalId != null ? '?intervalId=$intervalId' : '';
    unawaited(
      context.push<void>('${AppRoutes.intervalEdit}/$historyId$query').then((_) {
        if (context.mounted) unawaited(cubit.load(historyId));
      }),
    );
  }

  bool _hasChanges(HistorySessionEntity session) =>
      (_draftActionId != null && _draftActionId != session.actionNameId) ||
      _commentController.text != (session.comment ?? '') ||
      _draftStatus != null;

  Future<void> _save(BuildContext context, HistorySessionEntity session) async {
    final cubit = context.read<SessionEditCubit>();

    if (_commentController.text != (session.comment ?? '')) {
      await cubit.saveComment(_commentController.text);
      if (!context.mounted) return;
    }

    final draftActionId = _draftActionId;
    if (draftActionId != null && draftActionId != session.actionNameId) {
      final conflictHistoryId = await cubit.changeActivity(draftActionId);
      if (!context.mounted) return;
      if (conflictHistoryId != null) {
        final confirmed = await _confirmMerge(context);
        if (confirmed && context.mounted) await cubit.confirmMerge(conflictHistoryId);
      }
    }

    final draftStatus = _draftStatus;
    final draftStatusAt = _draftStatusAt;
    if (draftStatus != null && draftStatusAt != null) {
      await cubit.commitRunningStatus(target: draftStatus, at: draftStatusAt);
    }

    if (!context.mounted) return;
    context.pop();
  }

  Future<bool> _confirmMerge(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sessionMergeTitle),
        content: Text(l10n.sessionMergeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _confirmDeleteSession(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SessionEditCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.sessionDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.deleteSession();
  }
}

/// Icon + activity name + chevron; tap opens [ActivityPickerDialog]. The
/// pick is staged via [onPick] — SessionEditPage applies it on Save.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.currentActionId,
    required this.availableActions,
    required this.onPick,
  });

  final int currentActionId;
  final List<ActionNameEntity> availableActions;
  final ValueChanged<ActionNameEntity> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = availableActions.where((a) => a.id == currentActionId).firstOrNull;

    return ListTile(
      leading: current == null
          ? const Icon(Icons.help_outline)
          : FaIcon(faIconFromCode(current.icon), color: Color(current.color)),
      title: Text(current?.localizedName(l10n) ?? '—'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await ActivityPickerDialog.show(context);
        if (picked != null) onPick(picked);
      },
    );
  }
}

/// One-row segmented control for today's session: active/paused/stopped.
/// [onChanged] only stages the pick (SessionEditPage's draft state) — it is
/// applied to the database once, on Save, via
/// [SessionEditCubit.commitRunningStatus]. While staged as "active", a
/// [TickingTimer] runs off the local pick time so it visibly ticks even
/// though nothing has been written yet.
class _RunningStatusRow extends StatelessWidget {
  const _RunningStatusRow({
    required this.running,
    required this.draftStatus,
    required this.draftStatusAt,
    required this.onChanged,
  });

  final RunningWithNameEntity? running;
  final ActionStatus? draftStatus;
  final DateTime? draftStatusAt;
  final ValueChanged<ActionStatus> onChanged;

  ActionStatus get _originalStatus => running?.status ?? ActionStatus.stop;
  ActionStatus get _effectiveStatus => draftStatus ?? _originalStatus;

  /// accumulatedSec for the freshly staged pick: carries the original row's
  /// accumulated seconds when resuming a pause, folds in the elapsed active
  /// span when pausing/stopping a running original, otherwise starts at 0.
  int get _draftAccumulatedSec {
    final r = running;
    if (r == null) return 0;
    if (_originalStatus == ActionStatus.active && draftStatusAt != null) {
      final elapsed = draftStatusAt!.difference(r.startedAt).inSeconds;
      return r.accumulatedSec + (elapsed < 0 ? 0 : elapsed);
    }
    return r.accumulatedSec;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<ActionStatus>(
            segments: [
              ButtonSegment(value: ActionStatus.active, label: Text(l10n.actionStatusActive)),
              ButtonSegment(value: ActionStatus.pause, label: Text(l10n.actionStatusPause)),
              ButtonSegment(value: ActionStatus.stop, label: Text(l10n.actionStatusStop)),
            ],
            selected: {_effectiveStatus},
            onSelectionChanged: (selected) => onChanged(selected.first),
          ),
          if (_effectiveStatus != ActionStatus.stop)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TickingTimer(
                startedAt: draftStatus == ActionStatus.active
                    ? draftStatusAt ?? DateTime.now()
                    : running?.startedAt ?? DateTime.now(),
                accumulatedSec: draftStatus != null
                    ? _draftAccumulatedSec
                    : running?.accumulatedSec ?? 0,
                isActive: _effectiveStatus == ActionStatus.active,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}
