import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/gen/app_localizations.dart';
import 'package:timefocus/shared/enums/action_mode.dart';
import 'package:timefocus/shared/enums/pomodoro_type.dart';
import 'package:timefocus/shared/widgets/action_localization.dart';
import 'package:timefocus/shared/widgets/fa_icon_helper.dart';
import 'package:timefocus/shared/widgets/icon_picker/icon_picker_dialog.dart';

/// T076: create/edit an activity or group (FR-008/FR-043) — a standalone
/// route (AppRoutes.actionEdit), [actionId] null means "create new".
class ActionEditPage extends StatefulWidget {
  const ActionEditPage({this.actionId, super.key});

  final int? actionId;

  @override
  State<ActionEditPage> createState() => _ActionEditPageState();
}

class _ActionEditPageState extends State<ActionEditPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  bool _loading = true;
  ActionNameEntity? _existing;
  List<ActionNameEntity> _allActions = const [];

  int _icon = 0xf111;
  int _color = 0xFF4A6FA5;
  bool _isGroup = false;
  int? _groupId;
  ActionMode _mode = ActionMode.nothing;
  PomodoroType _pomodoroType = PomodoroType.normal;
  int? _breakActionId;
  bool _pauseOthers = false;
  bool _archived = false;
  bool _isSystem = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final repository = getIt<ActionNameRepository>();
    _allActions = await repository.watchAll().first;
    final actionId = widget.actionId;
    if (actionId != null) {
      final result = await repository.getById(actionId);
      _existing = result.valueOrNull;
      final e = _existing;
      if (e != null) {
        _nameController.text = e.name;
        _descriptionController.text = e.description ?? '';
        _durationController.text = e.defaultDurationSec?.toString() ?? '';
        _icon = e.icon;
        _color = e.color;
        _isGroup = e.isGroup;
        _groupId = e.groupId;
        _mode = e.mode;
        _pomodoroType = e.pomodoroType ?? PomodoroType.normal;
        _breakActionId = e.breakActionId;
        _pauseOthers = e.pauseOthers;
        _archived = e.archived;
        _isSystem = e.isSystem;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.actionId == null ? l10n.createAction : l10n.editAction)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final groups = _allActions.where((a) => a.isGroup && a.id != widget.actionId).toList();
    final breakCandidates = _allActions
        .where((a) => a.mode == ActionMode.breakFor && a.id != widget.actionId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.actionId == null
              ? (_isGroup ? l10n.createGroup : l10n.createAction)
              : l10n.editAction,
        ),
        actions: [
          if (_existing != null) ...[
            IconButton(
              icon: Icon(_archived ? Icons.unarchive_outlined : Icons.archive_outlined),
              tooltip: l10n.archiveAction,
              onPressed: () => _toggleArchived(context),
            ),
            if (!_isSystem)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.delete,
                onPressed: () => _confirmDelete(context),
              ),
          ],
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: _nameController.text.trim().isEmpty ? null : () => _save(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.actionName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: l10n.actionDescription),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: FaIcon(faIconFromCode(_icon)),
                  title: Text(l10n.actionIcon),
                  onTap: () async {
                    final picked = await IconPickerDialog.show(
                      context,
                      initialIcon: faIconFromCode(_icon),
                      selectedColor: Color(_color),
                    );
                    if (picked != null) setState(() => _icon = picked.codePoint);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Color(_color), radius: 12),
                  title: Text(l10n.actionColor),
                  onTap: () => _pickColor(context),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.actionGroup),
            value: _isGroup,
            onChanged: widget.actionId == null ? (v) => setState(() => _isGroup = v) : null,
          ),
          if (!_isGroup) ...[
            DropdownButtonFormField<int?>(
              initialValue: _groupId,
              decoration: InputDecoration(labelText: l10n.actionGroup),
              items: [
                DropdownMenuItem(child: Text(l10n.noBreakAction)),
                for (final g in groups)
                  DropdownMenuItem(value: g.id, child: Text(g.localizedName(l10n))),
              ],
              onChanged: (v) => setState(() => _groupId = v),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ActionMode>(
              segments: [
                ButtonSegment(value: ActionMode.nothing, label: Text(l10n.actionModeNothing)),
                ButtonSegment(value: ActionMode.pomodoro, label: Text(l10n.actionModePomodoro)),
                ButtonSegment(value: ActionMode.breakFor, label: Text(l10n.actionModeBreakFor)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            if (_mode == ActionMode.pomodoro) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<PomodoroType>(
                initialValue: _pomodoroType,
                decoration: InputDecoration(labelText: l10n.actionPomodoro),
                items: [
                  DropdownMenuItem(value: PomodoroType.short, child: Text(l10n.pomodoroTypeShort)),
                  DropdownMenuItem(
                    value: PomodoroType.normal,
                    child: Text(l10n.pomodoroTypeNormal),
                  ),
                  DropdownMenuItem(value: PomodoroType.long, child: Text(l10n.pomodoroTypeLong)),
                ],
                onChanged: (v) => setState(() => _pomodoroType = v ?? _pomodoroType),
              ),
              DropdownButtonFormField<int?>(
                initialValue: _breakActionId,
                decoration: InputDecoration(labelText: l10n.chooseBreakAction),
                items: [
                  DropdownMenuItem(child: Text(l10n.noBreakAction)),
                  for (final b in breakCandidates)
                    DropdownMenuItem(value: b.id, child: Text(b.localizedName(l10n))),
                ],
                onChanged: (v) => setState(() => _breakActionId = v),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.actionPauseOthers),
              value: _pauseOthers,
              onChanged: (v) => setState(() => _pauseOthers = v),
            ),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.actionDefaultDuration),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    var picked = Color(_color);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.actionColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: picked,
              onColorChanged: (c) => picked = c,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    if ((confirmed ?? false) && mounted) {
      setState(() => _color = picked.toARGB32());
    }
  }

  Future<void> _toggleArchived(BuildContext context) async {
    final id = widget.actionId;
    if (id == null) return;
    final repository = getIt<ActionNameRepository>();
    final result = await repository.setArchived(id, archived: !_archived);
    if (!context.mounted) return;
    if (result.isFailure) {
      logger.e('failed to change archived state', error: result.errorOrNull);
      return;
    }
    setState(() => _archived = !_archived);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;
    final id = widget.actionId;
    if (id == null) return;
    final result = await getIt<ActionNameRepository>().delete(id);
    if (!context.mounted) return;
    if (result.isFailure) {
      logger.e('failed to delete activity', error: result.errorOrNull);
      return;
    }
    context.pop();
  }

  Future<void> _save(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final duration = int.tryParse(_durationController.text.trim());

    final entity = ActionNameEntity(
      id: widget.actionId ?? 0,
      name: name,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      color: _color,
      icon: _icon,
      isGroup: _isGroup,
      groupId: _isGroup ? null : _groupId,
      mode: _isGroup ? ActionMode.nothing : _mode,
      pomodoroType: !_isGroup && _mode == ActionMode.pomodoro ? _pomodoroType : null,
      breakActionId: !_isGroup && _mode == ActionMode.pomodoro ? _breakActionId : null,
      pauseOthers: !_isGroup && _pauseOthers,
      defaultDurationSec: _isGroup ? null : duration,
      isSystem: _isSystem,
      archived: _archived,
    );

    final repository = getIt<ActionNameRepository>();
    final result = widget.actionId == null
        ? await repository.create(entity)
        : await repository.update(entity);
    if (!context.mounted) return;
    if (result.isFailure) {
      logger.e('failed to save activity', error: result.errorOrNull);
      return;
    }
    context.pop();
  }
}
