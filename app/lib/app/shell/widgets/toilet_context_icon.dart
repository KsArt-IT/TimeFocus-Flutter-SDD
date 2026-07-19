import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/constants/system_actions.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/features/tracker/presentation/bloc/action_bloc.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';

/// Toilet HUD icon: shown when HudContextType.toilet wins priority (a
/// pomodoro break with showToiletOnBreak, or a recent drink with
/// showToiletOnWater). Tap starts the system "Туалет" activity — during a
/// break this does not interrupt it (FR-010b, handled by StartActionUseCase
/// itself; no special-casing needed here).
class ToiletContextIcon extends StatelessWidget {
  const ToiletContextIcon({required this.pulsing, super.key});

  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: AppConstants.minTapTargetDp,
      height: AppConstants.minTapTargetDp,
      child: IconButton(
        tooltip: l10n.systemActionToilet,
        onPressed: () => _onTap(context),
        icon: AnimatedScale(
          duration: const Duration(milliseconds: 600),
          scale: pulsing ? 1.15 : 1.0,
          child: FaIcon(
            faIconFromCode(0xf7d8),
            color: Theme.of(context).colorScheme.tertiary,
            semanticLabel: l10n.systemActionToilet,
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    final actionBloc = context.read<ActionBloc>();
    context.read<HudCubit>().onToiletTapped();
    final result = await getIt<ActionNameRepository>().getBySystemName(SystemActionKeys.toilet);
    final toilet = result.valueOrNull;
    if (toilet != null) {
      actionBloc.add(ActionEvent.started(toilet.id));
    }
  }
}
