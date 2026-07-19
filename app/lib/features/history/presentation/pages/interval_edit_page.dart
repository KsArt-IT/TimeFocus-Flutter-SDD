import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:timefocus/features/history/domain/entities/history_interval_edit.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/history/presentation/cubit/session_edit_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// FR-040: date+time editing, quick-adjust buttons (now/−5/−1/+1/+5 min),
/// inline validation (end < start blocks save), overlap → warning toast,
/// save allowed anyway.
class IntervalEditPage extends StatefulWidget {
  const IntervalEditPage({
    required this.historyId,
    this.existing,
    this.activityName,
    super.key,
  });

  final int historyId;
  final HistoryIntervalEditEntity? existing;

  /// The session's activity, shown as the app bar title when known — falls
  /// back to the generic "Edit interval" title otherwise.
  final String? activityName;

  @override
  State<IntervalEditPage> createState() => _IntervalEditPageState();
}

class _IntervalEditPageState extends State<IntervalEditPage> {
  late DateTime _startedAt;
  late DateTime _finishedAt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startedAt = widget.existing?.startedAt ?? now.subtract(const Duration(minutes: 30));
    _finishedAt = widget.existing?.finishedAt ?? now;
  }

  bool get _isValid => !_finishedAt.isBefore(_startedAt);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: widget.activityName != null ? Text(widget.activityName!) : Text(l10n.editInterval),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.intervalDelete,
              onPressed: () async {
                await context.read<SessionEditCubit>().deleteInterval(widget.existing!.id);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: _isValid ? _save : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DateTimeField(
            label: l10n.intervalStart,
            value: _startedAt,
            onChanged: (v) => setState(() => _startedAt = v),
          ),
          const SizedBox(height: 16),
          _DateTimeField(
            label: l10n.intervalEnd,
            value: _finishedAt,
            onChanged: (v) => setState(() => _finishedAt = v),
          ),
          if (!_isValid)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l10n.intervalEndBeforeStart,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final cubit = context.read<SessionEditCubit>();
    final overlap = await cubit.saveInterval(
      HistoryIntervalEdit(
        id: widget.existing?.id,
        historyId: widget.historyId,
        startedAt: _startedAt,
        finishedAt: _finishedAt,
      ),
    );
    if (!mounted) return;
    if (overlap == OverlapCheck.warning) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.intervalOverlapWarning)),
      );
    }
    Navigator.of(context).pop();
  }
}

/// One label + a date button (left) and a time button (right) that both
/// edit the same [value], plus quick-adjust buttons for the time part.
class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.label, required this.value, required this.onChanged});

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  static const _quickAdjustMinutes = [-5, -1, 1, 5];

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
    return Column(
      crossAxisAlignment: .end,
      children: [
        Align(
          alignment: .centerStart,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(context),
                child: Text(
                  DateFormat.yMMMd(l10n.localeName).format(value),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            InkWell(
              onTap: () => _pickTime(context),
              child: Text(_hm(value), style: Theme.of(context).textTheme.headlineSmall),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: .end,
          spacing: 8,
          children: [
            for (final minutes in _quickAdjustMinutes)
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

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
