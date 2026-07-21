import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/core/utils/motion_utils.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/hud_context_type.dart';

class HudContextIcon extends StatelessWidget {
  const HudContextIcon({
    required this.contextType,
    required this.pulsing,
    super.key,
  });

  final HudContextType contextType;
  final bool pulsing;

  Future<void> _onTap(BuildContext context) async {
    if (contextType == .toilet) {
      final actionBloc = context.read<ActionBloc>();
      context.read<HudCubit>().onToiletTapped();
      final result = await getIt<ActionNameRepository>().getBySystemName(
        SystemActionKeys.toilet.name,
      );
      final toilet = result.valueOrNull;
      if (toilet != null) {
        actionBloc.add(ActionEvent.started(toilet.id));
      }
    } else {
      context.read<HudCubit>().dismissContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = contextType.label(l10n);

    return IconButton(
      tooltip: label,
      onPressed: () => _onTap(context),
      icon: AnimatedScale(
        duration: const Duration(milliseconds: 600),
        scale: pulsing && shouldAnimate(context) ? 1.15 : 1.0,
        child: FaIcon(
          contextType.icon,
          color: theme.colorScheme.secondary,
          semanticLabel: label,
        ),
      ),
    );
  }
}
