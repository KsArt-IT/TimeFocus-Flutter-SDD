import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/features/settings/domain/entities/user_settings_entity.dart';

part 'app_settings_state.freezed.dart';

@freezed
abstract class AppSettingsState with _$AppSettingsState {
  const AppSettingsState._();

  const factory AppSettingsState({
    required UserSettingsEntity settings,
    @Default(false) bool ready,
  }) = _AppSettingsState;

  /// null means "follow system locale".
  Locale? get locale => settings.language == 'system' ? null : Locale(settings.language);
}
