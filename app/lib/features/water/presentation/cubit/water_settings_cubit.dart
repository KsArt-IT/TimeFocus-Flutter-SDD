import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/water/domain/entities/water_quick_button_entity.dart';
import 'package:timefocus/features/water/domain/entities/water_settings_entity.dart';
import 'package:timefocus/features/water/domain/repositories/water_repository.dart';
import 'package:timefocus/features/water/presentation/cubit/water_settings_state.dart';

export 'package:timefocus/features/water/presentation/cubit/water_settings_state.dart';

/// Screen-scoped cubit for WaterSettingsPage (contracts/blocs.md): goal/
/// reminder settings are edited locally and persisted explicitly via
/// [save]; quick-button toggles and reminder-time add/remove persist right
/// away, same as the previous direct-repository-call behavior.
@injectable
class WaterSettingsCubit extends Cubit<WaterSettingsState> {
  WaterSettingsCubit(this._water) : super(const WaterSettingsState.loading());

  final WaterRepository _water;

  WaterSettingsEntity _settings = const WaterSettingsEntity();
  List<int> _reminderTimes = const [];
  List<WaterQuickButtonEntity> _quickButtons = const [];

  StreamSubscription<List<WaterQuickButtonEntity>>? _quickButtonsSub;

  Future<void> subscribe() async {
    final settingsResult = await _water.currentSettings();
    final timesResult = await _water.reminderTimes();
    if (isClosed) return;
    if (settingsResult.isFailure) {
      emit(WaterSettingsState.error(settingsResult.errorOrNull!));
      return;
    }
    _settings = settingsResult.valueOrNull ?? const WaterSettingsEntity();
    _reminderTimes = timesResult.valueOrNull ?? const [];

    _quickButtonsSub = _water.watchAllQuickButtons().listen((buttons) {
      _quickButtons = buttons;
      _emit();
    }, onError: (Object e) => logger.e('quick buttons stream error', error: e));

    _emit();
  }

  /// Updates the local draft (not persisted until [save]).
  void updateDraft(WaterSettingsEntity settings) {
    _settings = settings;
    _emit();
  }

  Future<bool> save() async {
    final result = await _water.saveSettings(_settings);
    if (result.isFailure) {
      logger.e('failed to save water settings', error: result.errorOrNull);
      return false;
    }
    return true;
  }

  Future<void> addReminderTime(int minutes) async {
    final times = [..._reminderTimes, minutes]..sort();
    final result = await _water.saveReminderTimes(times);
    if (isClosed) return;
    if (result.isFailure) {
      logger.e('failed to save reminder times', error: result.errorOrNull);
      return;
    }
    _reminderTimes = times;
    _emit();
  }

  Future<void> removeReminderTime(int minutes) async {
    final times = _reminderTimes.where((t) => t != minutes).toList();
    final result = await _water.saveReminderTimes(times);
    if (isClosed) return;
    if (result.isFailure) {
      logger.e('failed to save reminder times', error: result.errorOrNull);
      return;
    }
    _reminderTimes = times;
    _emit();
  }

  Future<void> toggleQuickButton(WaterQuickButtonEntity button, {required bool active}) async {
    final result = await _water.saveQuickButton(button.copyWith(isActive: active));
    if (result.isFailure) {
      logger.e('failed to toggle quick button', error: result.errorOrNull);
    }
  }

  Future<void> addQuickButton({
    required String label,
    required int icon,
    required int volume,
  }) async {
    final result = await _water.saveQuickButton(
      WaterQuickButtonEntity(
        id: 0,
        volume: volume,
        label: label,
        icon: icon,
        sortOrder: _quickButtons.length,
      ),
    );
    if (result.isFailure) {
      logger.e('failed to add quick button', error: result.errorOrNull);
    }
  }

  Future<void> updateQuickButton(WaterQuickButtonEntity button) async {
    final result = await _water.saveQuickButton(button);
    if (result.isFailure) {
      logger.e('failed to update quick button', error: result.errorOrNull);
    }
  }

  Future<void> deleteQuickButton(int id) async {
    final result = await _water.deleteQuickButton(id);
    if (result.isFailure) {
      logger.e('failed to delete quick button', error: result.errorOrNull);
    }
  }

  /// Drag reorder from the settings list.
  Future<void> reorderQuickButtons(List<int> orderedIds) async {
    final result = await _water.reorderQuickButtons(orderedIds);
    if (result.isFailure) {
      logger.e('failed to reorder quick buttons', error: result.errorOrNull);
    }
  }

  void _emit() {
    emit(
      WaterSettingsState.loaded(
        settings: _settings,
        reminderTimes: _reminderTimes,
        quickButtons: _quickButtons,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _quickButtonsSub?.cancel();
    return super.close();
  }
}
