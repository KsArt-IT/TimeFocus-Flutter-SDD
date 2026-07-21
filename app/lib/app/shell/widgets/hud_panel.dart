import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/app/shell/widgets/hud_context_icon.dart';
import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/core/router/app_router.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/drink_localization.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';

/// HUD panel: water bar with a goal marker and a not-color-only deficit
/// indicator (FR-047), glass tap-to-log button (long-press for the drink
/// list), and the contextual icon (FR — Туалет>Еда>Спорт>Сон priority).
class HudPanel extends StatelessWidget {
  const HudPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HudCubit, HudState>(
      builder: (context, state) => state.maybeMap(
        orElse: SizedBox.shrink,
        loaded: _HudPanelContent.new,
      ),
    );
  }
}

class _HudPanelContent extends StatelessWidget {
  const _HudPanelContent(this.state);

  final HudLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contextType = state.context;

    return Padding(
      padding: const .symmetric(horizontal: AppDimens.inset3x, vertical: AppDimens.inset1x),
      child: Row(
        children: [
          Expanded(child: _WaterPanel(state: state)),
          const SizedBox(width: 8),
          _GlassButton(pulsing: state.glassBlinking),
          SizedBox(
            width: AppConstants.minTapTargetDp,
            height: AppConstants.minTapTargetDp,
            child: contextType == .empty
                ? Icon(
                    Icons.notifications_none_rounded,
                    size: AppDimens.iconSize,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  )
                : HudContextIcon(contextType: contextType, pulsing: state.contextPulsing),
          ),
        ],
      ),
    );
  }
}

class _WaterPanel extends StatelessWidget {
  const _WaterPanel({required this.state});

  final HudLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final behindSchedule = state.currentMl < state.expectedByNowMl;
    final goalReached = state.currentMl >= state.goalMl;

    return Semantics(
      button: true,
      label: l10n.holdForWaterHistory,
      child: GestureDetector(
        behavior: .opaque,
        onLongPress: () => context.push(AppRoutes.historyWater),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                if (behindSchedule)
                  Icon(Icons.arrow_downward, size: 14, color: theme.colorScheme.error)
                else if (goalReached)
                  Icon(Icons.check_circle, size: 14, color: theme.colorScheme.primary),
                if (behindSchedule || goalReached) const SizedBox(width: AppDimens.inset1x),
                Expanded(
                  child: Text(
                    goalReached
                        ? l10n.waterGoalReached
                        : behindSchedule
                        ? l10n.waterDeficit(state.expectedByNowMl - state.currentMl)
                        : l10n.waterRemaining(state.goalMl - state.currentMl),
                    style: theme.textTheme.bodySmall,
                    overflow: .ellipsis,
                  ),
                ),
                Text(
                  l10n.waterCurrentAndGoal(state.currentMl, state.goalMl),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppDimens.inset1x),
            _WaterBar(
              currentMl: state.currentMl,
              goalMl: state.goalMl,
              expectedByNowMl: state.expectedByNowMl,
              behindSchedule: behindSchedule,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterBar extends StatelessWidget {
  const _WaterBar({
    required this.currentMl,
    required this.goalMl,
    required this.expectedByNowMl,
    required this.behindSchedule,
  });

  final int currentMl;
  final int goalMl;
  final int expectedByNowMl;
  final bool behindSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = goalMl <= 0 ? 0.0 : (currentMl / goalMl).clamp(0.0, 1.0);
    final expectedFraction = goalMl <= 0 ? 0.0 : (expectedByNowMl / goalMl).clamp(0.0, 1.0);

    return SizedBox(
      height: AppDimens.inset4x,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            LinearProgressIndicator(
              value: fraction,
              borderRadius: .circular(AppDimens.radius1x),
              minHeight: AppDimens.inset2x,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: behindSchedule ? theme.colorScheme.error : theme.colorScheme.tertiary,
            ),
            Positioned(
              left: constraints.maxWidth * expectedFraction - AppDimens.inset3x,
              bottom: -6,
              child: Icon(
                Icons.arrow_drop_up_rounded,
                size: AppDimens.iconSize,
                color: behindSchedule ? theme.colorScheme.error : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.pulsing});

  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<HudCubit>();
    return SizedBox(
      width: AppConstants.minTapTargetDp,
      height: AppConstants.minTapTargetDp,
      child: Tooltip(
        message: l10n.holdForMore,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.minTapTargetDp / 2),
          onTap: () => unawaited(cubit.logWater(AppConstants.defaultWaterPortionMl)),
          onLongPress: () => _showQuickButtons(context, cubit),
          child: Semantics(
            button: true,
            label: l10n.addDrink,
            child: Icon(
              pulsing ? Icons.local_drink : Icons.local_drink_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickButtons(BuildContext context, HudCubit cubit) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: cubit.quickButtons
                .where((b) => b.isActive)
                .map((b) => _QuickButtonTile(button: b, cubit: cubit))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _QuickButtonTile extends StatelessWidget {
  const _QuickButtonTile({required this.button, required this.cubit});

  final WaterQuickButtonEntity button;
  final HudCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: FaIcon(faIconFromCode(button.icon)),
      title: Text(button.label.localizedLabel(l10n)),
      trailing: Text(l10n.drinkVolumeMl(button.volume)),
      onTap: () {
        context.pop();
        unawaited(cubit.logDrink(button.id));
      },
    );
  }
}
