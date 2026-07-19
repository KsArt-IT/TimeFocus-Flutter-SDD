import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/activity_grid_tile.dart';

/// Centered dialog for picking a single (non-group) activity — the same
/// grid/group navigation as ActionGrid, but self-contained: it keeps its
/// own group state instead of driving the global ActionBloc (which would
/// otherwise also move the tracker screen's grid).
class ActivityPickerDialog extends StatefulWidget {
  const ActivityPickerDialog({super.key});

  /// Shows the dialog; resolves to the picked activity, or null if
  /// dismissed without a selection.
  static Future<ActionNameEntity?> show(BuildContext context) =>
      showDialog<ActionNameEntity>(context: context, builder: (_) => const ActivityPickerDialog());

  @override
  State<ActivityPickerDialog> createState() => _ActivityPickerDialogState();
}

class _ActivityPickerDialogState extends State<ActivityPickerDialog> {
  int? _groupId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final columns = context.read<AppSettingsCubit>().state.settings.columnCount;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              automaticallyImplyLeading: false,
              title: Text(l10n.changeActivity),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: StreamBuilder<List<ActionNameEntity>>(
                stream: getIt<ActionNameRepository>().watchGrid(groupId: _groupId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final actions = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_groupId != null)
                          TextButton.icon(
                            onPressed: () => setState(() => _groupId = null),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(l10n.back),
                          ),
                        if (actions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(l10n.allActions, textAlign: TextAlign.center),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: actions.length,
                            itemBuilder: (context, index) {
                              final action = actions[index];
                              return ActivityGridTile(
                                action: action,
                                onTap: () {
                                  if (action.isGroup) {
                                    setState(() => _groupId = action.id);
                                  } else {
                                    Navigator.of(context).pop(action);
                                  }
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
