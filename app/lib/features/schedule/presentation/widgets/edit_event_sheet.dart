import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/meal_slot.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';
import 'package:timefocus/shared/widgets/schedule_event_localization.dart';

Future<void> showEditEventSheet(
  BuildContext context, {
  ScheduleEventEntity? existing,
  int initialTimeMinutes = 8 * 60,
}) {
  final cubit = context.read<ScheduleCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: _EditEventForm(existing: existing, initialTimeMinutes: initialTimeMinutes),
    ),
  );
}

class _EditEventForm extends StatefulWidget {
  const _EditEventForm({required this.existing, required this.initialTimeMinutes});

  final ScheduleEventEntity? existing;
  final int initialTimeMinutes;

  @override
  State<_EditEventForm> createState() => _EditEventFormState();
}

class _EditEventFormState extends State<_EditEventForm> {
  late ScheduleEventType _type;
  MealSlot? _mealSlot;
  late int _timeMinutes;
  late int _durationMinutes;
  late bool _isStrictly;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? ScheduleEventType.custom;
    _mealSlot = e?.mealSubtype ?? MealSlot.lunch;
    _timeMinutes = e?.timeMinutes ?? widget.initialTimeMinutes;
    _durationMinutes = e?.durationMinutes ?? 30;
    _isStrictly = e?.isStrictly ?? false;
    _isEnabled = e?.isEnabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<ScheduleEventType>(
              initialValue: _type,
              items: ScheduleEventType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(_typeLabel(l10n, t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            if (_type == ScheduleEventType.meal)
              DropdownButtonFormField<MealSlot>(
                initialValue: _mealSlot,
                items: MealSlot.values
                    .map(
                      (m) => DropdownMenuItem(value: m, child: Text(m.localizedName(l10n))),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _mealSlot = v ?? _mealSlot),
              ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.scheduleEventTime),
              trailing: Text(_formatMinutes(_timeMinutes)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _timeMinutes ~/ 60, minute: _timeMinutes % 60),
                );
                if (picked != null) {
                  setState(() => _timeMinutes = picked.hour * 60 + picked.minute);
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.scheduleEventDuration),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setState(
                      () => _durationMinutes = (_durationMinutes - 5).clamp(5, 1440),
                    ),
                  ),
                  Text('$_durationMinutes'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(
                      () => _durationMinutes = (_durationMinutes + 5).clamp(5, 1440),
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.scheduleEventStrict),
              subtitle: Text(
                _isStrictly ? l10n.scheduleEventStrictHint : l10n.scheduleEventFlexibleHint,
              ),
              value: _isStrictly,
              onChanged: (v) => setState(() => _isStrictly = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.scheduleEventEnabled),
              value: _isEnabled,
              onChanged: (v) => setState(() => _isEnabled = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton(
                    onPressed: () {
                      unawaited(context.read<ScheduleCubit>().deleteEvent(widget.existing!.id));
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.delete),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final cubit = context.read<ScheduleCubit>();
    final event =
        (widget.existing ??
                const ScheduleEventEntity(type: ScheduleEventType.custom, timeMinutes: 0))
            .copyWith(
              type: _type,
              mealSubtype: _type == ScheduleEventType.meal ? _mealSlot : null,
              timeMinutes: _timeMinutes,
              durationMinutes: _durationMinutes,
              isStrictly: _isStrictly,
              isEnabled: _isEnabled,
            );
    if (widget.existing == null) {
      unawaited(cubit.createEvent(event));
    } else {
      unawaited(cubit.updateEvent(event));
    }
    Navigator.of(context).pop();
  }

  String _typeLabel(AppLocalizations l10n, ScheduleEventType t) =>
      t.systemAction?.label(l10n) ??
      (t == ScheduleEventType.wakeUp ? l10n.scheduleEventWakeUp : l10n.scheduleEventCustom);

  String _formatMinutes(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
