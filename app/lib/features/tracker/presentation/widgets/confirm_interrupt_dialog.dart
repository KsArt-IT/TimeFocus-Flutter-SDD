import 'package:flutter/material.dart';

import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';

/// FR-011: starting a second Pomodoro requires confirmation; refusal changes
/// nothing. Returns true when the user confirms the interruption.
Future<bool> showConfirmInterruptDialog(BuildContext context, ActionNameEntity action) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.pomodoroInterrupted),
      content: Text('${l10n.startAction}: ${action.localizedName(l10n)}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
