import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';

class CircleFaIcon extends StatelessWidget {
  const CircleFaIcon({
    required this.icon,
    required this.color,
    this.name,
    super.key,
  });

  final String? name;
  final int icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: FaIcon(
        faIconFromCode(icon),
        color: color,
        size: AppDimens.iconSizeSmall,
        semanticLabel: name,
      ),
    );
  }
}
