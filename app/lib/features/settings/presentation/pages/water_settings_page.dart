import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/core/constants/app_constants.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/core/extension/datetime_ext.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/presentation/cubit/water_settings_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/water_reminder_mode.dart';
import 'package:timefocus/shared/widgets/drink_localization.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';
import 'package:timefocus/shared/widgets/icon_picker/icon_picker_dialog.dart';

/// T078: goal mode/value, reminder mode (interval or scheduled times),
/// quick-add buttons, toilet-suggestion flags.
class WaterSettingsPage extends StatelessWidget {
  const WaterSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WaterSettingsCubit>(
      create: (_) {
        final cubit = getIt<WaterSettingsCubit>();
        unawaited(cubit.subscribe());
        return cubit;
      },
      child: const _WaterSettingsPageContent(),
    );
  }
}

class _WaterSettingsPageContent extends StatelessWidget {
  const _WaterSettingsPageContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<WaterSettingsCubit, WaterSettingsState>(
      builder: (context, state) => state.maybeMap(
        orElse: () => Scaffold(
          appBar: AppBar(title: Text(l10n.settingsWater)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        loaded: (s) => _WaterSettingsForm(state: s),
      ),
    );
  }
}

class _WaterSettingsForm extends StatelessWidget {
  const _WaterSettingsForm({required this.state});

  final WaterSettingsLoaded state;

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await context.read<WaterSettingsCubit>().save();
    if (!context.mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.done)));
  }

  Future<void> _addReminderTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null || !context.mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    unawaited(context.read<WaterSettingsCubit>().addReminderTime(minutes));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<WaterSettingsCubit>();
    final settings = state.settings;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsWater),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: () => unawaited(_save(context)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.waterAddQuickButton,
        onPressed: () => _showQuickButtonSheet(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const .fromLTRB(
          AppDimens.inset4x,
          AppDimens.inset4x,
          AppDimens.inset4x,
          AppDimens.bottomPaddingMedium,
        ),
        children: [
          Text(l10n.waterGoal, style: textTheme.labelLarge),
          const SizedBox(height: AppDimens.inset2x),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.waterGoalModeManual)),
              ButtonSegment(value: true, label: Text(l10n.waterGoalModeByWeight)),
            ],
            selected: {settings.weightMode},
            onSelectionChanged: (s) => cubit.updateDraft(settings.copyWith(weightMode: s.first)),
          ),
          const SizedBox(height: AppDimens.inset2x),
          if (settings.weightMode)
            _NumberField(
              label: l10n.waterWeightKg,
              value: settings.weightKg,
              onChanged: (v) => cubit.updateDraft(settings.copyWith(weightKg: v)),
            )
          else
            _NumberField(
              label: l10n.waterGoal,
              value: settings.dailyWaterGoal,
              step: 100,
              onChanged: (v) => cubit.updateDraft(settings.copyWith(dailyWaterGoal: v)),
            ),
          _NumberField(
            label: l10n.waterExtraLoad,
            value: settings.extraLoad,
            step: 100,
            onChanged: (v) => cubit.updateDraft(settings.copyWith(extraLoad: v)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.inset3x),
            child: Text(l10n.waterExtraLoadHint, style: textTheme.bodySmall),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.waterReminderRemindersEnabled),
            value: settings.remindersEnabled,
            onChanged: (v) => cubit.updateDraft(settings.copyWith(remindersEnabled: v)),
          ),
          SegmentedButton<WaterReminderMode>(
            segments: [
              ButtonSegment(
                value: WaterReminderMode.interval,
                label: Text(l10n.waterReminderModeInterval),
              ),
              ButtonSegment(
                value: WaterReminderMode.scheduled,
                label: Text(l10n.waterReminderModeScheduled),
              ),
            ],
            selected: {settings.reminderMode},
            onSelectionChanged: (s) => cubit.updateDraft(settings.copyWith(reminderMode: s.first)),
          ),
          const SizedBox(height: AppDimens.inset2x),
          if (settings.reminderMode == WaterReminderMode.interval)
            _NumberField(
              label: l10n.waterReminderInterval(settings.reminderInterval),
              value: settings.reminderInterval,
              step: 5,
              onChanged: (v) => cubit.updateDraft(settings.copyWith(reminderInterval: v)),
            )
          else ...[
            Text(l10n.waterReminderTimes, style: textTheme.labelLarge),
            for (final minutes in state.reminderTimes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(minutes.formatMinutes()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => unawaited(cubit.removeReminderTime(minutes)),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => unawaited(_addReminderTime(context)),
              icon: const Icon(Icons.add),
              label: Text(l10n.waterReminderAddTime),
            ),
          ],
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showToiletOnWater),
            value: settings.showToiletOnWater,
            onChanged: (v) => cubit.updateDraft(settings.copyWith(showToiletOnWater: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showToiletOnBreak),
            value: settings.showToiletOnBreak,
            onChanged: (v) => cubit.updateDraft(settings.copyWith(showToiletOnBreak: v)),
          ),
          const Divider(),
          Text(l10n.waterQuickButtons, style: textTheme.labelLarge),
          _QuickButtonsReorderList(buttons: state.quickButtons),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => onChanged((value - step).clamp(0, 100000)),
          ),
          Text('$value'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged((value + step).clamp(0, 100000)),
          ),
        ],
      ),
    );
  }
}

class _QuickButtonsReorderList extends StatelessWidget {
  const _QuickButtonsReorderList({required this.buttons});

  final List<WaterQuickButtonEntity> buttons;

  void _onReorderItem(BuildContext context, int oldIndex, int newIndex) {
    final reordered = [...buttons];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    unawaited(
      context.read<WaterSettingsCubit>().reorderQuickButtons(
        reordered.map((b) => b.id).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: buttons.length,
      itemBuilder: (context, index) => _QuickButtonTile(
        key: ValueKey(buttons[index].id),
        button: buttons[index],
      ),
      onReorderItem: (oldIndex, newIndex) => _onReorderItem(context, oldIndex, newIndex),
    );
  }
}

class _QuickButtonTile extends StatelessWidget {
  const _QuickButtonTile({required this.button, super.key});

  final WaterQuickButtonEntity button;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: FaIcon(faIconFromCode(button.icon)),
      title: Text(localizedDrinkLabel(l10n, button.label)),
      subtitle: Text(l10n.drinkVolumeMl(button.volume)),
      onTap: () => _showQuickButtonSheet(context, existing: button),
      trailing: Switch(
        value: button.isActive,
        onChanged: (v) => unawaited(
          context.read<WaterSettingsCubit>().toggleQuickButton(button, active: v),
        ),
      ),
    );
  }
}

void _showQuickButtonSheet(BuildContext context, {WaterQuickButtonEntity? existing}) {
  final cubit = context.read<WaterSettingsCubit>();
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: _QuickButtonForm(existing: existing),
      ),
    ),
  );
}

class _QuickButtonForm extends StatefulWidget {
  const _QuickButtonForm({this.existing});

  final WaterQuickButtonEntity? existing;

  @override
  State<_QuickButtonForm> createState() => _QuickButtonFormState();
}

class _QuickButtonFormState extends State<_QuickButtonForm> {
  late final _nameController = TextEditingController(text: widget.existing?.label);
  late int _icon = widget.existing?.icon ?? FontAwesomeIcons.glassWater.codePoint;
  late int _volume = widget.existing?.volume ?? 200;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _delete() {
    unawaited(context.read<WaterSettingsCubit>().deleteQuickButton(widget.existing!.id));
    context.pop();
  }

  void _submit() {
    final label = _nameController.text.trim();
    final existing = widget.existing;
    if (existing == null) {
      unawaited(
        context.read<WaterSettingsCubit>().addQuickButton(
          label: label,
          icon: _icon,
          volume: _volume,
        ),
      );
    } else {
      unawaited(
        context.read<WaterSettingsCubit>().updateQuickButton(
          existing.copyWith(label: label, icon: _icon, volume: _volume),
        ),
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: .fromLTRB(
        AppDimens.inset4x,
        AppDimens.inset4x,
        AppDimens.inset4x,
        MediaQuery.of(context).viewInsets.bottom + AppDimens.inset4x,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(
              widget.existing == null ? l10n.waterAddQuickButton : l10n.edit,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.inset3x),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.waterQuickButtonName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppDimens.inset3x),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: FaIcon(faIconFromCode(_icon)),
              title: Text(l10n.waterQuickButtonIcon),
              onTap: () async {
                final picked = await IconPickerDialog.show(
                  context,
                  initialIcon: faIconFromCode(_icon),
                  selectedColor: Theme.of(context).colorScheme.primary,
                );
                if (picked != null) setState(() => _icon = picked.codePoint);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.waterQuickButtonVolume),
              trailing: Row(
                mainAxisSize: .min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(
                      () => _volume = (_volume - AppConstants.waterDrinkMinMl).clamp(
                        AppConstants.waterDrinkMinMl,
                        AppConstants.waterDrinkMaxMl,
                      ),
                    ),
                  ),
                  Text(l10n.drinkVolumeMl(_volume)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(
                      () => _volume = (_volume + AppConstants.waterDrinkMinMl).clamp(
                        AppConstants.waterDrinkMinMl,
                        AppConstants.waterDrinkMaxMl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.inset3x),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton(
                    onPressed: _delete,
                    child: Text(l10n.delete),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppDimens.inset2x),
                FilledButton(
                  onPressed: _nameController.text.trim().isEmpty ? null : _submit,
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
