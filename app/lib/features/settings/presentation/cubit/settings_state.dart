import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:timefocus/core/errors/app_failure.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';

part 'settings_state.freezed.dart';

/// Activities list for ActionsSettingsPage (T076/T081) — every activity,
/// any group, archived or not.
@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.loading() = SettingsLoading;

  const factory SettingsState.loaded(List<ActionNameEntity> actions) = SettingsLoaded;

  const factory SettingsState.error(AppFailure failure) = SettingsError;
}
