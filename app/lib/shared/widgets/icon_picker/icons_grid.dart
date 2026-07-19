import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/icon_picker/fa_icon_name.dart';
import 'package:timefocus/shared/widgets/icon_picker/icon_tile.dart';

class IconsGrid extends StatelessWidget {
  const IconsGrid({
    required this.icons,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
    super.key,
  });

  final List<FaIconName> icons;
  final FaIconData selectedIcon;
  final Color selectedColor;
  final ValueChanged<FaIconData> onIconSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (icons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noIconsFound,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final iconData = icons[index];
        final isSelected = selectedIcon == iconData.faIcon;

        return IconTile(
          faIcon: iconData.faIcon,
          isSelected: isSelected,
          selectedColor: selectedColor,
          onTap: () => onIconSelected(iconData.faIcon),
        );
      },
    );
  }
}
