import 'package:flutter/material.dart';

import 'package:timefocus/shared/widgets/color_picker/color_rgb_slider.dart';

class ColorCustomPicker extends StatelessWidget {
  const ColorCustomPicker({required this.selectedColor, required this.onColorChanged, super.key});

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  int get _red => (selectedColor.toARGB32() >> 16) & 0xFF;
  int get _green => (selectedColor.toARGB32() >> 8) & 0xFF;
  int get _blue => selectedColor.toARGB32() & 0xFF;

  void _onRgbChanged(int red, int green, int blue) =>
      onColorChanged(Color.fromARGB(255, red, green, blue));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(width: double.infinity, height: 80),
          ),
          const SizedBox(height: 16),
          Text(
            '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ColorRgbSlider(
            label: 'R',
            value: _red,
            color: Colors.red,
            onChanged: (v) => _onRgbChanged(v, _green, _blue),
          ),
          const SizedBox(height: 8),
          ColorRgbSlider(
            label: 'G',
            value: _green,
            color: Colors.green,
            onChanged: (v) => _onRgbChanged(_red, v, _blue),
          ),
          const SizedBox(height: 8),
          ColorRgbSlider(
            label: 'B',
            value: _blue,
            color: Colors.blue,
            onChanged: (v) => _onRgbChanged(_red, _green, v),
          ),
        ],
      ),
    );
  }
}
