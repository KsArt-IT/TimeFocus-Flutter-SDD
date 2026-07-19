import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// Curated set of activity icons — covers the common work/health/leisure
/// cases without pulling in FontAwesome's full icon list (thousands of
/// entries, most irrelevant here).
const List<FaIconData> kActionIconChoices = [
  FontAwesomeIcons.briefcase,
  FontAwesomeIcons.laptop,
  FontAwesomeIcons.book,
  FontAwesomeIcons.penToSquare,
  FontAwesomeIcons.mugHot,
  FontAwesomeIcons.utensils,
  FontAwesomeIcons.bed,
  FontAwesomeIcons.personRunning,
  FontAwesomeIcons.dumbbell,
  FontAwesomeIcons.heartPulse,
  FontAwesomeIcons.personWalking,
  FontAwesomeIcons.bicycle,
  FontAwesomeIcons.droplet,
  FontAwesomeIcons.pills,
  FontAwesomeIcons.toilet,
  FontAwesomeIcons.spa,
  FontAwesomeIcons.handsPraying,
  FontAwesomeIcons.music,
  FontAwesomeIcons.gamepad,
  FontAwesomeIcons.palette,
  FontAwesomeIcons.car,
  FontAwesomeIcons.plane,
  FontAwesomeIcons.house,
  FontAwesomeIcons.cartShopping,
  FontAwesomeIcons.tree,
  FontAwesomeIcons.paw,
  FontAwesomeIcons.phone,
  FontAwesomeIcons.envelope,
  FontAwesomeIcons.star,
  FontAwesomeIcons.circle,
];

/// Grid dialog for picking one of [kActionIconChoices]; resolves to the
/// picked icon's codePoint (as stored in ActionNames.icon), or null if
/// dismissed.
class IconPickerDialog extends StatelessWidget {
  const IconPickerDialog({super.key});

  static Future<int?> show(BuildContext context) =>
      showDialog<int>(context: context, builder: (_) => const IconPickerDialog());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              automaticallyImplyLeading: false,
              title: Text(l10n.actionIcon),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            Flexible(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: kActionIconChoices.length,
                itemBuilder: (context, index) {
                  final icon = kActionIconChoices[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.pop(icon.codePoint),
                    child: FaIcon(icon),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
