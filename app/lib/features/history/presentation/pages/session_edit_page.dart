import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/history/presentation/cubit/session_edit_cubit.dart';
import 'package:timefocus/features/history/presentation/pages/interval_edit_page.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<SessionEditCubit, SessionEditState>(
      listenWhen: (previous, current) => current is SessionEditDeleted,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        if (state is SessionEditLoaded) _syncDraft(state.session);
        final hasChanges = state is SessionEditLoaded && _hasChanges(state.session);

        return Scaffold(
          appBar: AppBar(
            title: state is SessionEditLoaded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
            SessionEditLoaded(:final session, :final availableActions) => ListView(
              children: [
                _ActivityRow(
                  currentActionId: _draftActionId ?? session.actionNameId,
                  availableActions: availableActions,
                  onPick: (picked) => setState(() => _draftActionId = picked.id),
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
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<SessionEditCubit>(),
                          child: IntervalEditPage(historyId: session.historyId, existing: interval),
                        ),
                      ),
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l10n.addInterval),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SessionEditCubit>(),
                        child: IntervalEditPage(historyId: session.historyId),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          },
        );
      },
    );
  }

  bool _hasChanges(HistorySessionEntity session) =>
      (_draftActionId != null && _draftActionId != session.actionNameId) ||
      _commentController.text != (session.comment ?? '');

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
