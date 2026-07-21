import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_edit.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/history/presentation/cubit/session_edit_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/date_time_field.dart';

/// FR-040: date+time editing, quick-adjust buttons (now/−5/−1/+1/+5 min),
/// inline validation (end < start blocks save), overlap → warning toast,
/// save allowed anyway. A standalone route (AppRoutes.intervalEdit) — it
/// owns its own [SessionEditCubit] and loads [historyId] itself, so
/// [intervalId] (when editing an existing interval, via the ?intervalId=
/// query param) is enough to recover both the interval and its activity's
/// name.
class IntervalEditPage extends StatelessWidget {
  const IntervalEditPage({required this.historyId, this.intervalId, super.key});

  final int historyId;
  final int? intervalId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionEditCubit>(
      create: (_) {
        final cubit = getIt<SessionEditCubit>();
        unawaited(cubit.load(historyId));
        return cubit;
      },
      child: _IntervalEditContent(intervalId: intervalId),
    );
  }
}

class _IntervalEditContent extends StatefulWidget {
  const _IntervalEditContent({required this.intervalId});

  final int? intervalId;

  @override
  State<_IntervalEditContent> createState() => _IntervalEditContentState();
}

class _IntervalEditContentState extends State<_IntervalEditContent> {
  DateTime? _startedAt;
  DateTime? _finishedAt;
  bool _synced = false;

  bool get _isValid =>
      _startedAt != null && _finishedAt != null && !_finishedAt!.isBefore(_startedAt!);

  /// Seeds the editable fields from the loaded session's matching interval
  /// (or sensible defaults for a new one) — once, not on every rebuild, so
  /// in-progress edits survive unrelated state changes.
  void _syncDraft(HistorySessionEntity session) {
    if (_synced) return;
    _synced = true;
    final existing = _existingInterval(session);
    final now = DateTime.now();
    _startedAt = existing?.startedAt ?? now.subtract(const Duration(minutes: 30));
    _finishedAt = existing?.finishedAt ?? now;
  }

  HistoryIntervalEditEntity? _existingInterval(HistorySessionEntity session) =>
      widget.intervalId == null
      ? null
      : session.intervals.where((i) => i.id == widget.intervalId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SessionEditCubit, SessionEditState>(
      builder: (context, state) {
        if (state is! SessionEditLoaded) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.editInterval)),
            body: Center(
              child: state is SessionEditError
                  ? Text(state.failure.localizedMessage(l10n))
                  : const CircularProgressIndicator(),
            ),
          );
        }
        _syncDraft(state.session);
        final existing = _existingInterval(state.session);
        final activityName = state.availableActions
            .where((a) => a.id == state.session.actionNameId)
            .firstOrNull
            ?.localizedName(l10n);

        return Scaffold(
          appBar: AppBar(
            title: activityName != null ? Text(activityName) : Text(l10n.editInterval),
            actions: [
              if (existing != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.intervalDelete,
                  onPressed: () async {
                    await context.read<SessionEditCubit>().deleteInterval(existing.id);
                    if (context.mounted) context.pop();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: l10n.save,
                onPressed: _isValid
                    ? () => _save(context, state.session.historyId, existing?.id)
                    : null,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DateTimeField(
                label: l10n.intervalStart,
                value: _startedAt!,
                onChanged: (v) => setState(() => _startedAt = v),
              ),
              const SizedBox(height: 16),
              DateTimeField(
                label: l10n.intervalEnd,
                value: _finishedAt!,
                onChanged: (v) => setState(() => _finishedAt = v),
              ),
              if (!_isValid)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.intervalEndBeforeStart,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(BuildContext context, int historyId, int? existingId) async {
    final cubit = context.read<SessionEditCubit>();
    final overlap = await cubit.saveInterval(
      HistoryIntervalEdit(
        id: existingId,
        historyId: historyId,
        startedAt: _startedAt!,
        finishedAt: _finishedAt!,
      ),
    );
    if (!context.mounted) return;
    if (overlap == OverlapCheck.warning) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.intervalOverlapWarning)),
      );
    }
    context.pop();
  }
}
