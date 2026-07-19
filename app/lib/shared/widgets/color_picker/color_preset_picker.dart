import 'package:flutter/material.dart';

import 'package:timefocus/shared/widgets/color_picker/color_circle.dart';
import 'package:timefocus/shared/widgets/color_picker/colors_data.dart';

class ColorPresetPicker extends StatelessWidget {
  const ColorPresetPicker({required this.selectedColor, required this.onColorChanged, super.key});

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: ColorsData.presetColors.length,
      itemBuilder: (context, index) {
        final color = ColorsData.presetColors[index];
        final isSelected = selectedColor.toARGB32() == color.toARGB32();

        return ColorCircle(
          color: color,
          isSelected: isSelected,
          onTap: () => onColorChanged(color),
        );
      },
    );
  }
}
