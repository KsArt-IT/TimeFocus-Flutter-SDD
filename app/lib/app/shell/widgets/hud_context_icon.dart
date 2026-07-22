import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/core/utils/motion_utils.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/features/water/domain/entities/hud_queue_item_entity.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';

class HudContextIcon extends StatelessWidget {
  const HudContextIcon({
    required this.item,
    super.key,
  });

  final HudQueueItemEntity item;

  Future<void> _onTap(BuildContext context) async {
    context.read<ActionBloc>().add(ActionEvent.startSystemAction(item.action));
    context.read<HudCubit>().onQueueItemTapped(item.id, item.action);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = item.action.label(l10n);

    return IconButton(
      tooltip: label,
      onPressed: () => _onTap(context),
      icon: AnimatedScale(
        duration: const Duration(milliseconds: 600),
        scale: shouldAnimate(context) ? 1.15 : 1.0,
        child: FaIcon(
          item.action.icon,
          color: theme.colorScheme.secondary,
          semanticLabel: label,
        ),
      ),
    );
  }
}
