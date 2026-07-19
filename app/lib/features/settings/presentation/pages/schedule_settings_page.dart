import 'dart:async';

import 'package:flutter/material.dart';

import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/schedule/domain/entities/schedule_event_entity.dart';
import 'package:timefocus/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/day_type.dart';
import 'package:timefocus/shared/enums/meal_slot.dart';
import 'package:timefocus/shared/enums/schedule_event_type.dart';
import 'package:timefocus/shared/widgets/schedule_event_localization.dart';

/// T080: weekday/weekend schedule sets, independent of "today" (unlike
/// SchedulePage, which only ever shows the current day's set).
class ScheduleSettingsPage extends StatefulWidget {
  const ScheduleSettingsPage({super.key});

  @override
  State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage> {
  DayType _dayType = DayType.weekday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSchedule)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<DayType>(
              segments: [
                ButtonSegment(
                  value: DayType.weekday,
                  label: Text(l10n.scheduleDayTypeWeekday),
                ),
                ButtonSegment(
                  value: DayType.weekend,
                  label: Text(l10n.scheduleDayTypeWeekend),
                ),
              ],
              selected: {_dayType},
              onSelectionChanged: (s) => setState(() => _dayType = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ScheduleEventEntity>>(
              stream: getIt<ScheduleRepository>().watchDay(_dayType),
              builder: (context, snapshot) {
                final events = snapshot.data ?? const [];
                if (events.isEmpty) return Center(child: Text(l10n.scheduleNoEvents));
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      title: Text(event.displayName(l10n)),
                      subtitle: Text(_formatMinutes(event.timeMinutes)),
                      trailing: event.isStrictly ? const Icon(Icons.priority_high) : null,
                      onTap: () => _openEditor(context, existing: event),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.scheduleAddEvent,
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditor(BuildContext context, {ScheduleEventEntity? existing}) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _ScheduleEventForm(dayType: _dayType, existing: existing),
      ),
    );
  }

  String _formatMinutes(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}

class _ScheduleEventForm extends StatefulWidget {
  const _ScheduleEventForm({required this.dayType, this.existing});

  final DayType dayType;
  final ScheduleEventEntity? existing;

  @override
  State<_ScheduleEventForm> createState() => _ScheduleEventFormState();
}

class _ScheduleEventFormState extends State<_ScheduleEventForm> {
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
    _timeMinutes = e?.timeMinutes ?? 8 * 60;
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
              items: [
                for (final t in ScheduleEventType.values)
                  DropdownMenuItem(value: t, child: Text(_typeLabel(l10n, t))),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            if (_type == ScheduleEventType.meal)
              DropdownButtonFormField<MealSlot>(
                initialValue: _mealSlot,
                items: [
                  for (final m in MealSlot.values)
                    DropdownMenuItem(value: m, child: Text(m.localizedName(l10n))),
                ],
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
                    onPressed: () =>
                        setState(() => _durationMinutes = (_durationMinutes - 5).clamp(5, 1440)),
                  ),
                  Text('$_durationMinutes'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () =>
                        setState(() => _durationMinutes = (_durationMinutes + 5).clamp(5, 1440)),
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
                    onPressed: () async {
                      final result = await getIt<ScheduleRepository>().delete(
                        widget.existing!.id,
                      );
                      if (result.isFailure) {
                        logger.e('failed to delete schedule event', error: result.errorOrNull);
                      }
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: Text(l10n.delete),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: Text(l10n.save)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
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
              dayType: widget.dayType,
            );
    final repository = getIt<ScheduleRepository>();
    final result = widget.existing == null
        ? await repository.create(event)
        : await repository.update(event);
    if (result.isFailure) {
      logger.e('failed to save schedule event', error: result.errorOrNull);
    }
    if (mounted) Navigator.of(context).pop();
  }

  String _typeLabel(AppLocalizations l10n, ScheduleEventType t) => switch (t) {
    ScheduleEventType.wakeUp => l10n.scheduleEventWakeUp,
    ScheduleEventType.meal => l10n.scheduleEventMeal,
    ScheduleEventType.work => l10n.scheduleEventWork,
    ScheduleEventType.sport => l10n.scheduleEventSport,
    ScheduleEventType.sleep => l10n.scheduleEventSleep,
    ScheduleEventType.custom => l10n.scheduleEventCustom,
  };

  String _formatMinutes(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
