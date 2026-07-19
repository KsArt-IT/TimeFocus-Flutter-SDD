import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:timefocus/features/history/domain/entities/history_interval_edit.dart';
import 'package:timefocus/features/history/domain/entities/history_session_entity.dart';
import 'package:timefocus/features/history/presentation/cubit/session_edit_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// FR-040: quick-adjust buttons (now/−5/−1/+1/+5 min), inline validation
/// (end < start blocks save), overlap → warning toast, save allowed anyway.
class IntervalEditPage extends StatefulWidget {
  const IntervalEditPage({required this.historyId, this.existing, super.key});

  final int historyId;
  final HistoryIntervalEditEntity? existing;

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
        title: Text(l10n.editInterval),
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TimeField(
            label: l10n.intervalStart,
            value: _startedAt,
            onChanged: (v) => setState(() => _startedAt = v),
          ),
          const SizedBox(height: 16),
          _TimeField(
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isValid ? _save : null,
            child: Text(l10n.save),
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

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.value, required this.onChanged});

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  static const _quickAdjustMinutes = [-5, -1, 1, 5];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(value),
            );
            if (picked != null) {
              onChanged(
                DateTime(value.year, value.month, value.day, picked.hour, picked.minute),
              );
            }
          },
          child: Text(_hm(value), style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => onChanged(DateTime.now()),
              child: Text(l10n.now),
            ),
            for (final minutes in _quickAdjustMinutes)
              OutlinedButton(
                onPressed: () => onChanged(value.add(Duration(minutes: minutes))),
                child: Text(minutes > 0 ? '+$minutes' : '$minutes'),
              ),
          ],
        ),
      ],
    );
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
