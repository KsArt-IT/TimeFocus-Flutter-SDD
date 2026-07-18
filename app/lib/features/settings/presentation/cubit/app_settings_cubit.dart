import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/settings/domain/entities/user_settings_entity.dart';
import 'package:timefocus/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:timefocus/shared/enums/app_theme_mode.dart';

/// Global cubit: theme, locale, time format, grid size — reactive on the
/// user_settings Drift stream (instant theme/language switch, FR/SC-008).
@lazySingleton
class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._repository)
    : super(const AppSettingsState(settings: UserSettingsEntity())) {
    _subscription = _repository.watch().listen(
      (settings) => emit(AppSettingsState(settings: settings, ready: true)),
      onError: (Object e) => logger.e('user settings stream error', error: e),
    );
  }

  final UserSettingsRepository _repository;
  StreamSubscription<UserSettingsEntity>? _subscription;

  Future<void> setThemeMode(AppThemeMode mode) => _save(state.settings.copyWith(themeMode: mode));

  Future<void> setLanguage(String language) => _save(state.settings.copyWith(language: language));

  Future<void> setTimeFormat(int timeFormat) =>
      _save(state.settings.copyWith(timeFormat: timeFormat));

  Future<void> setShortTime({required bool isShortTime}) =>
      _save(state.settings.copyWith(isShortTime: isShortTime));

  Future<void> setGridSize({required int columns, required int rows}) =>
      _save(state.settings.copyWith(columnCount: columns, rowCount: rows));

  Future<void> setName(String name) => _save(state.settings.copyWith(name: name));

  Future<void> setNotificationsEnabled({required bool enabled}) =>
      _save(state.settings.copyWith(notificationsEnabled: enabled));

  Future<void> completeOnboarding({String? name}) => _save(
    state.settings.copyWith(onboardingCompleted: true, name: name ?? state.settings.name),
  );

  Future<void> setReminderRequest({required bool requested}) =>
      _save(state.settings.copyWith(reminderRequest: requested));

  Future<void> _save(UserSettingsEntity settings) async {
    final result = await _repository.save(settings);
    if (isClosed) return;
    result.fold(
      success: (_) {},
      failure: (e) => logger.e('failed to save user settings', error: e),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
