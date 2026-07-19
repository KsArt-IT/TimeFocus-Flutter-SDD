import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';

/// One activity/group tile: icon (+ folder badge for groups) and name.
/// Shared between the tracker's ActionGrid and any activity picker.
class ActivityGridTile extends StatelessWidget {
  const ActivityGridTile({required this.action, required this.onTap, super.key});

  final ActionNameEntity action;
  final VoidCallback onTap;

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
          onTap: onTap,
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
