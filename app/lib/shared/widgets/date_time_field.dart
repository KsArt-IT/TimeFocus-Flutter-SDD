import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/core/extension/datetime_ext.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// One label + a date button (left) and a time button (right) that both
/// edit the same [value], plus quick-adjust buttons for the time part.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day, value.hour, value.minute));
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (picked != null) {
      onChanged(DateTime(value.year, value.month, value.day, picked.hour, picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: .end,
      children: [
        Align(
          alignment: .topStart,
          child: Text(label, style: textTheme.labelLarge),
        ),
        const SizedBox(height: AppDimens.inset2x),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(context),
                child: Text(
                  value.yMMMd(l10n.localeName),
                  style: textTheme.headlineSmall,
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(context),
                child: Text(
                  value.displayHM(),
                  style: textTheme.headlineSmall,
                  textAlign: .end,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.inset2x),
        Wrap(
          spacing: 8,
          alignment: .end,
          children: [
            for (final minutes in AppConstants.intervalQuickAdjustMinutes)
              OutlinedButton(
                onPressed: () => onChanged(value.add(Duration(minutes: minutes))),
                child: Text(minutes > 0 ? '+$minutes' : '$minutes'),
              ),
            OutlinedButton(
              onPressed: () => onChanged(DateTime.now()),
              child: Text(l10n.now),
            ),
          ],
        ),
      ],
    );
  }
}
