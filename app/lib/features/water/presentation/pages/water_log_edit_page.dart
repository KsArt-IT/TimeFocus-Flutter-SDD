import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timefocus/core/constants/app_dimens.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/water/domain/entities/water_log_entity.dart';
import 'package:timefocus/features/water/presentation/cubit/water_log_edit_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/widgets/date_time_field.dart';

/// Edits a single water log entry's time and volume — opened from
/// WaterLogTile in the History screen's water mode.
class WaterLogEditPage extends StatelessWidget {
  const WaterLogEditPage({required this.logId, super.key});

  final int logId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WaterLogEditCubit>(
      create: (_) {
        final cubit = getIt<WaterLogEditCubit>();
        unawaited(cubit.load(logId));
        return cubit;
      },
      child: _WaterLogEditContent(logId: logId),
    );
  }
}

class _WaterLogEditContent extends StatefulWidget {
  const _WaterLogEditContent({required this.logId});

  final int logId;

  @override
  State<_WaterLogEditContent> createState() => _WaterLogEditContentState();
}

class _WaterLogEditContentState extends State<_WaterLogEditContent> {
  final _volumeController = TextEditingController();
  DateTime? _createdAt;
  bool _synced = false;

  bool get _isValid => _createdAt != null && (int.tryParse(_volumeController.text) ?? 0) > 0;

  /// Seeds the editable fields from the loaded log, once — not on every
  /// rebuild, so in-progress edits survive unrelated state changes.
  void _syncDraft(WaterLogEntity log) {
    if (_synced) return;
    _synced = true;
    _createdAt = log.createdAt;
    _volumeController.text = log.volume.toString();
  }

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final cubit = context.read<WaterLogEditCubit>();
    await cubit.save(
      id: widget.logId,
      volume: int.parse(_volumeController.text),
      createdAt: _createdAt!,
    );
    if (!context.mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<WaterLogEditCubit, WaterLogEditState>(
      builder: (context, state) {
        if (state is! WaterLogEditLoaded) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.editWaterLog)),
            body: Center(
              child: state is WaterLogEditError
                  ? Text(state.failure.localizedMessage(l10n))
                  : const CircularProgressIndicator(),
            ),
          );
        }
        _syncDraft(state.log);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.editWaterLog),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.waterLogDelete,
                onPressed: () async {
                  await context.read<WaterLogEditCubit>().deleteLog(widget.logId);
                  if (context.mounted) context.pop();
                },
              ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: l10n.save,
                onPressed: _isValid ? () => _save(context) : null,
              ),
            ],
          ),
          body: ListView(
            padding: const .all(AppDimens.inset4x),
            children: [
              DateTimeField(
                label: l10n.waterLogTime,
                value: _createdAt!,
                onChanged: (v) => setState(() => _createdAt = v),
              ),
              const SizedBox(height: AppDimens.inset4x),
              TextField(
                controller: _volumeController,
                keyboardType: .number,
                textAlign: .end,
                decoration: InputDecoration(labelText: l10n.waterVolumeMl),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        );
      },
    );
  }
}
