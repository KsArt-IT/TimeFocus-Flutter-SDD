import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/app/shell/widgets/toilet_context_icon.dart';
import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/presentation/cubit/hud_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/drink_type.dart';
import 'package:timefocus/shared/enums/hud_context_type.dart';
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final behindSchedule = state.currentMl < state.expectedByNowMl;
    final goalReached = state.currentMl >= state.goalMl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (behindSchedule)
                      Icon(Icons.arrow_downward, size: 14, color: theme.colorScheme.error)
                    else if (goalReached)
                      Icon(Icons.check_circle, size: 14, color: theme.colorScheme.primary),
                    if (behindSchedule || goalReached) const SizedBox(width: 4),
                    Text(
                      goalReached
                          ? l10n.waterGoalReached
                          : behindSchedule
                          ? l10n.waterDeficit(state.expectedByNowMl - state.currentMl)
                          : l10n.waterRemaining(state.goalMl - state.currentMl),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _WaterBar(
                  currentMl: state.currentMl,
                  goalMl: state.goalMl,
                  expectedByNowMl: state.expectedByNowMl,
                  behindSchedule: behindSchedule,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _GlassButton(pulsing: state.glassBlinking),
          if (state.context != HudContextType.toilet && state.context != HudContextType.empty)
            _ContextIcon(contextType: state.context, pulsing: state.contextPulsing)
          else if (state.context == HudContextType.toilet)
            ToiletContextIcon(pulsing: state.contextPulsing),
        ],
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
      height: 10,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: behindSchedule ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
            ),
            Positioned(
              left: (constraints.maxWidth * expectedFraction).clamp(0, constraints.maxWidth - 2),
              child: Container(width: 2, height: 10, color: theme.colorScheme.onSurface),
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
      title: Text(_drinkLabel(l10n, button.label)),
      trailing: Text(l10n.drinkVolumeMl(button.volume)),
      onTap: () {
        Navigator.of(context).pop();
        unawaited(cubit.logDrink(button.id));
      },
    );
  }
}

String _drinkLabel(AppLocalizations l10n, DrinkType label) => switch (label) {
  DrinkType.tea => l10n.drinkTypeTea,
  DrinkType.coffee => l10n.drinkTypeCoffee,
  DrinkType.milk => l10n.drinkTypeMilk,
  DrinkType.bottle => l10n.drinkTypeBottle,
  DrinkType.water => l10n.drinkTypeWater,
};

class _ContextIcon extends StatelessWidget {
  const _ContextIcon({required this.contextType, required this.pulsing});

  final HudContextType contextType;
  final bool pulsing;

  @override
  Widget build(BuildContext buildContext) {
    final l10n = AppLocalizations.of(buildContext);
    final theme = Theme.of(buildContext);
    final (icon, label) = switch (contextType) {
      HudContextType.meal => (FontAwesomeIcons.utensils, l10n.scheduleEventMeal),
      HudContextType.sport => (FontAwesomeIcons.personRunning, l10n.scheduleEventSport),
      HudContextType.sleep => (FontAwesomeIcons.bed, l10n.scheduleEventSleep),
      HudContextType.toilet || HudContextType.empty => (FontAwesomeIcons.circle, ''),
    };

    return SizedBox(
      width: AppConstants.minTapTargetDp,
      height: AppConstants.minTapTargetDp,
      child: IconButton(
        tooltip: label,
        onPressed: () => buildContext.read<HudCubit>().dismissContext(),
        icon: AnimatedScale(
          duration: const Duration(milliseconds: 600),
          scale: pulsing ? 1.15 : 1.0,
          child: FaIcon(icon, color: theme.colorScheme.secondary, semanticLabel: label),
        ),
      ),
    );
  }
}
