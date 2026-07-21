import 'package:flutter/material.dart';
import 'package:timefocus/features/water/domain/entities/water_log_entity.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// One row of the "Water" mode list — tap opens the log editor.
class WaterLogTile extends StatelessWidget {
  const WaterLogTile({
    required this.log,
    required this.onTap,
    super.key,
  });

  final WaterLogEntity log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        child: Icon(Icons.local_drink, color: theme.colorScheme.primary),
      ),
      title: Text(_hm(log.createdAt)),
      trailing: Text(l10n.drinkVolumeMl(log.volume)),
      leadingAndTrailingTextStyle: theme.textTheme.bodyMedium,
    );
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
