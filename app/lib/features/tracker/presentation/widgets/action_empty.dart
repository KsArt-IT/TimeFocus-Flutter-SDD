import 'package:flutter/material.dart';
import 'package:timefocus/core/constants/app_dimens.dart';

class ActionEmpty extends StatelessWidget {
  const ActionEmpty({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const .all(AppDimens.inset4x),
      child: Column(
        mainAxisAlignment: .center,
        children: [
          Icon(
            icon,
            size: AppDimens.iconSizeLarge,
            color: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          Text(
            label,
            textAlign: .center,
          ),
        ],
      ),
    );
  }
}
