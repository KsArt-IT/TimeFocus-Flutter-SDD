import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';

/// Activity grid: configurable size, scrolls on overflow (FR-009), in-place
/// groups with a back button (FR-007), empty state.
class ActionGrid extends StatelessWidget {
  const ActionGrid({
    required this.actions,
    required this.columns,
    required this.rowCount,
    this.currentGroupId,
    super.key,
  });

  final List<ActionNameEntity> actions;
  final int columns;
  final int rowCount;
  final int? currentGroupId;

  static const double _spacing = 8;
  static const EdgeInsets _gridPadding = EdgeInsets.all(12);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (actions.isEmpty && currentGroupId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.allActions, textAlign: TextAlign.center),
        ),
      );
    }

    final totalRows = (actions.length / columns).ceil();
    final visibleRows = totalRows > rowCount ? rowCount : totalRows;
    final gridHeight =
        (AppConstants.actionItemHeight * visibleRows) +
        (_spacing * (visibleRows - 1)) +
        _gridPadding.vertical;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentGroupId != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => context.read<ActionBloc>().add(const ActionEvent.groupOpened(null)),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.back),
            ),
          ),
        SizedBox(
          height: gridHeight,
          child: GridView.builder(
            padding: _gridPadding,
            physics: totalRows <= rowCount
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: _spacing,
              crossAxisSpacing: _spacing,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) => _ActionGridTile(action: actions[index]),
          ),
        ),
      ],
    );
  }
}

class _ActionGridTile extends StatelessWidget {
  const _ActionGridTile({required this.action});

  final ActionNameEntity action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = Color(action.color);
    final name = action.localizedName(l10n);

    return Semantics(
      button: true,
      label: name,
      child: Material(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            final bloc = context.read<ActionBloc>();
            if (action.isGroup) {
              bloc.add(ActionEvent.groupOpened(action.id));
            } else {
              bloc.add(ActionEvent.started(action.id));
            }
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppConstants.minTapTargetDp,
              minHeight: AppConstants.minTapTargetDp,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FaIcon(faIconFromCode(action.icon), color: color, size: 26),
                    if (action.isGroup)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: Icon(Icons.folder, size: 12, color: theme.colorScheme.outline),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    name,
                    style: theme.textTheme.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
