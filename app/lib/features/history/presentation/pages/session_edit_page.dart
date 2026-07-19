import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/history/presentation/cubit/session_edit_cubit.dart';
import 'package:timefocus/features/history/presentation/pages/interval_edit_page.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
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

class _SessionEditContent extends StatelessWidget {
  const _SessionEditContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<SessionEditCubit, SessionEditState>(
      listenWhen: (previous, current) => current is SessionEditDeleted,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.sessionEditTitle),
          actions: [
            if (state is SessionEditLoaded)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.delete,
                onPressed: () => _confirmDeleteSession(context),
              ),
          ],
        ),
        body: switch (state) {
          SessionEditLoading() => const Center(child: CircularProgressIndicator()),
          SessionEditDeleted() => const SizedBox.shrink(),
          SessionEditError(:final failure) => Center(child: Text(failure.localizedMessage(l10n))),
          SessionEditLoaded(:final session, :final availableActions) => ListView(
            children: [
              ListTile(
                title: Text(l10n.changeActivity),
                trailing: DropdownButton<int>(
                  value: availableActions.any((a) => a.id == session.actionNameId)
                      ? session.actionNameId
                      : null,
                  items: availableActions
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(faIconFromCode(a.icon), size: 16, color: Color(a.color)),
                              const SizedBox(width: 8),
                              Text(a.localizedName(l10n)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      unawaited(context.read<SessionEditCubit>().changeActivity(id));
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  initialValue: session.comment ?? '',
                  decoration: InputDecoration(labelText: l10n.sessionComment),
                  onFieldSubmitted: (value) =>
                      unawaited(context.read<SessionEditCubit>().saveComment(value)),
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
              const Divider(),
              for (final interval in session.intervals)
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    '${_hm(interval.startedAt)} – ${_hm(interval.finishedAt)}',
                  ),
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
      ),
    );
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
