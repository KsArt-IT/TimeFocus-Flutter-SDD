import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/core/constants/app_dimens.dart';

import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/core/router/app_router.dart';
import 'package:timefocus/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';

/// T076: activity list — create/edit/archive; system activities can be
/// archived but never deleted (FR-043/FR-008).
class ActionsSettingsPage extends StatelessWidget {
  const ActionsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (_) => getIt<SettingsCubit>(),
      child: const _ActionsSettingsContent(),
    );
  }
}

class _ActionsSettingsContent extends StatelessWidget {
  const _ActionsSettingsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsActions)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => switch (state) {
          SettingsLoading() => const Center(child: CircularProgressIndicator()),
          SettingsError(:final failure) => Center(child: Text(failure.localizedMessage(l10n))),
          SettingsLoaded(:final actions) => _ReorderableActionsList(actions: actions),
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.createAction,
        onPressed: () => context.push(AppRoutes.actionEdit),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Flat display of root activities/groups (sortOrder within groupId==null)
/// with each group's members immediately following, indented (sortOrder
/// within that groupId). One [ReorderableListView] covers both, but a drag
/// is clamped to the dragged item's own contiguous scope so it can never
/// cross into another group's ordering or the root ordering.
class _ReorderableActionsList extends StatelessWidget {
  const _ReorderableActionsList({required this.actions});

  final List<ActionNameEntity> actions;

  List<ActionNameEntity> _flatten() {
    int cmp(ActionNameEntity a, ActionNameEntity b) =>
        a.sortOrder != b.sortOrder ? a.sortOrder.compareTo(b.sortOrder) : a.id.compareTo(b.id);

    final roots = actions.where((a) => a.groupId == null).sorted(cmp);
    final byGroup = groupBy(actions.where((a) => a.groupId != null), (a) => a.groupId);

    return [
      for (final root in roots) ...[
        root,
        if (root.isGroup) ...(byGroup[root.id] ?? const []).sorted(cmp),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final flat = _flatten();
    final cubit = context.read<SettingsCubit>();

    return ReorderableListView.builder(
      padding: const .only(bottom: AppDimens.bottomPaddingMedium),
      itemCount: flat.length,
      itemBuilder: (context, index) =>
          _ActionTile(key: ValueKey(flat[index].id), action: flat[index]),
      onReorderItem: (oldIndex, newIndex) => _onReorder(flat, cubit, oldIndex, newIndex),
    );
  }

  /// [newIndex] is already adjusted for the removed item (onReorderItem, not
  /// the deprecated onReorder), so it's the final insertion index directly.
  void _onReorder(List<ActionNameEntity> flat, SettingsCubit cubit, int oldIndex, int newIndex) {
    final list = [...flat];
    final moved = list.removeAt(oldIndex);

    // Clamp the drop to the moved item's own scope (root, or its group)
    // so a drag can never splice one scope's ordering into another's.
    final scopeIndexes = [
      for (var i = 0; i < list.length; i++)
        if (list[i].groupId == moved.groupId) i,
    ];
    final lowerBound = scopeIndexes.isEmpty ? 0 : scopeIndexes.first;
    final upperBound = scopeIndexes.isEmpty ? 0 : scopeIndexes.last + 1;
    final clampedIndex = newIndex.clamp(lowerBound, upperBound);
    list.insert(clampedIndex, moved);

    final scopedIds = [
      for (final a in list)
        if (a.groupId == moved.groupId) a.id,
    ];
    unawaited(cubit.reorder(scopedIds));
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, super.key});

  final ActionNameEntity action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitleParts = [
      if (action.isGroup) l10n.actionGroup,
      if (action.archived) l10n.actionArchived,
    ];

    return ListTile(
      contentPadding: EdgeInsets.only(left: action.groupId == null ? 16 : 40, right: 16),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          FaIcon(faIconFromCode(action.icon), color: Color(action.color)),
          if (action.isGroup)
            Positioned(
              right: -6,
              top: -4,
              child: Icon(Icons.folder, size: 14, color: Theme.of(context).colorScheme.outline),
            ),
        ],
      ),
      title: Text(action.localizedName(l10n)),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('${AppRoutes.actionEdit}/${action.id}'),
    );
  }
}
