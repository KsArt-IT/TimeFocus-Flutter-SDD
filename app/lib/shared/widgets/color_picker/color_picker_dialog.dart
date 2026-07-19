import 'package:flutter/material.dart';

import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/color_picker/color_custom_picker.dart';
import 'package:timefocus/shared/widgets/color_picker/color_preset_picker.dart';

/// Dialog for picking an activity's color (T076's color field).
///
/// Two modes: a preset grid (default) and a custom RGB slider picker.
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog._({required this.initialColor});

  final Color initialColor;

  /// Shows the dialog; resolves to the picked color, or null if dismissed
  /// without a selection.
  static Future<Color?> show(BuildContext context, {required Color initialColor}) =>
      showDialog<Color>(
        context: context,
        builder: (_) => ColorPickerDialog._(initialColor: initialColor),
      );

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late var _selectedColor = widget.initialColor;
  var _isCustomMode = false;

  void _onColorChanged(Color color) {
    if (_selectedColor == color) return;
    setState(() => _selectedColor = color);
  }

  void _toggleMode() => setState(() => _isCustomMode = !_isCustomMode);

  void _onClose(Color? color) => Navigator.of(context).pop(color);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        _isCustomMode ? l10n.other : l10n.selectColor,
        style: theme.textTheme.titleMedium,
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      content: SizedBox(
        width: 280,
        height: 340,
        child: _isCustomMode
            ? ColorCustomPicker(selectedColor: _selectedColor, onColorChanged: _onColorChanged)
            : ColorPresetPicker(selectedColor: _selectedColor, onColorChanged: _onColorChanged),
      ),
      actionsPadding: const EdgeInsets.all(8),
      actions: [
        OutlinedButton(
          onPressed: _toggleMode,
          child: Text(_isCustomMode ? l10n.presets : l10n.other),
        ),
        TextButton(onPressed: () => _onClose(null), child: Text(l10n.cancel)),
        TextButton(onPressed: () => _onClose(_selectedColor), child: Text(l10n.select)),
      ],
    );
  }
}
