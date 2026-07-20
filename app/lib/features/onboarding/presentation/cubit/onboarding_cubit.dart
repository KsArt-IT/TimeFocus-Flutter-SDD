import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:timefocus/core/utils/app_logger.dart';
import 'package:timefocus/features/notifications/data/datasources/notification_permission_service.dart';
import 'package:timefocus/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:timefocus/features/settings/domain/entities/user_settings_entity.dart';
import 'package:timefocus/features/settings/domain/repositories/user_settings_repository.dart';

export 'package:timefocus/features/onboarding/presentation/cubit/onboarding_state.dart';

/// T083: onboarding steps, fully skippable, optional name, notification
/// permission request with graceful refusal handling (FR-036/044).
@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._settingsRepository, this._permissionService)
    : super(const OnboardingState());

  static const int totalSteps = 3;

  final UserSettingsRepository _settingsRepository;
  final NotificationPermissionService _permissionService;

  void nextStep() {
    if (state.step >= totalSteps - 1) return;
    emit(state.copyWith(step: state.step + 1));
  }

  void previousStep() {
    if (state.step <= 0) return;
    emit(state.copyWith(step: state.step - 1));
  }

  void setName(String name) => emit(state.copyWith(name: name));

  Future<void> requestNotificationPermission() async {
    emit(state.copyWith(requestingPermission: true));
    final granted = await _permissionService.request();
    if (isClosed) return;
    emit(state.copyWith(requestingPermission: false));
    await _updateSettings(
      (s) => s.copyWith(reminderRequest: true, notificationsEnabled: granted),
    );
  }

  /// Skips the whole onboarding — no name recorded, defaults kept (FR-044).
  Future<void> skip() => _complete(name: '');

  Future<void> finish() => _complete(name: state.name.trim());

  Future<void> _complete({required String name}) async {
    await _updateSettings(
      (s) => s.copyWith(onboardingCompleted: true, name: name.isEmpty ? s.name : name),
    );
    if (isClosed) return;
    emit(state.copyWith(completed: true));
  }

  Future<void> _updateSettings(
    UserSettingsEntity Function(UserSettingsEntity) update,
  ) async {
    final current = await _settingsRepository.get();
    if (isClosed) return;
    final base = current.valueOrNull ?? const UserSettingsEntity();
    final result = await _settingsRepository.save(update(base));
    if (isClosed) return;
    result.fold(
      success: (_) {},
      failure: (e) => logger.e('failed to save onboarding settings', error: e),
    );
  }
}
