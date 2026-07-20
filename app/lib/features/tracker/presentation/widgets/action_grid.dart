import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/activity_grid_tile.dart';

/// Activity grid: configurable size, scrolls on overflow (FR-009), in-place
/// groups with a back button (FR-007), empty state.
class ActionGrid extends StatelessWidget {
  const ActionGrid({
    required this.actions,
    required this.columns,
    required this.maxRowCount,
    required this.isGroup,
    super.key,
  });

  final List<ActionNameEntity> actions;
  final int columns;
  final int maxRowCount;
  final bool isGroup;

  static const double _spacing = AppDimens.inset2x;
  static const EdgeInsets _gridPadding = EdgeInsets.symmetric(
    horizontal: AppDimens.inset3x,
    vertical: AppDimens.inset2x,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final itemCount = isGroup ? actions.length + 1 : actions.length;

    final totalRows = (itemCount / columns).ceil();
    final visibleRows = totalRows > maxRowCount ? maxRowCount : totalRows;

    final totalHeight =
        AppConstants.actionItemHeight * visibleRows +
        _spacing * (visibleRows - 1) +
        (visibleRows < 3 ? _gridPadding.vertical : 0);

    final size = MediaQuery.of(context).size;
    final itemWidth = (size.width - _spacing * (columns - 1)) / columns;

    return SizedBox(
      height: totalHeight,
      child: GridView.builder(
        padding: _gridPadding,
        physics: totalRows <= maxRowCount
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: _spacing,
          mainAxisSpacing: _spacing,
          childAspectRatio: itemWidth / AppConstants.actionItemHeight,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (isGroup && index == 0) {
            return GestureDetector(
              onTap: () => context.read<ActionBloc>().add(const ActionEvent.groupOpened(null)),
              behavior: .opaque,
              child: Column(
                mainAxisAlignment: .center,
                spacing: AppDimens.inset1x,
                children: [
                  const Icon(Icons.arrow_back),
                  Text(l10n.back, style: theme.textTheme.labelSmall),
                ],
              ),
            );
          }

          final actionIndex = isGroup ? index - 1 : index;
          final action = actions[actionIndex];

          return ActivityGridTile(
            key: ValueKey(action.id),
            action: action,
            onTap: () {
              final bloc = context.read<ActionBloc>();
              if (action.isGroup) {
                bloc.add(ActionEvent.groupOpened(action.id));
              } else {
                bloc.add(ActionEvent.started(action.id));
              }
            },
          );
        },
      ),
    );
  }
}
