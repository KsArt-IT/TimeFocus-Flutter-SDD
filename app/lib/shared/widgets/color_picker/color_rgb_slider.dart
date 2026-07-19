import 'package:flutter/material.dart';

class ColorRgbSlider extends StatelessWidget {
  const ColorRgbSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
    super.key,
  });

  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label)),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.3),
              overlayColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              max: 255,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(width: 40, child: Text(value.toString(), textAlign: TextAlign.end)),
      ],
    );
  }
}
