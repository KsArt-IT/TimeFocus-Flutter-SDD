import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

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
          SettingsLoaded(:final actions) => ListView.builder(
            itemCount: actions.length,
            itemBuilder: (context, index) => _ActionTile(action: actions[index]),
          ),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final ActionNameEntity action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtitleParts = [
      if (action.isGroup) l10n.actionGroup,
      if (action.archived) l10n.actionArchived,
    ];

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          FaIcon(faIconFromCode(action.icon), color: Color(action.color)),
          if (action.isGroup)
            Positioned(
              right: -6,
              top: -4,
              child: Icon(
                Icons.folder,
                size: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
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
