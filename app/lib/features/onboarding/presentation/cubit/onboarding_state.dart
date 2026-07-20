import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int step,
    @Default('') String name,
    @Default(false) bool requestingPermission,
    @Default(false) bool completed,
  }) = _OnboardingState;
}
