import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    required this.faIcon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
    super.key,
  });

  final FaIconData faIcon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: selectedColor, width: 2) : null,
        ),
        child: Center(
          child: FaIcon(
            faIcon,
            size: 20,
            color: isSelected ? selectedColor : colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
