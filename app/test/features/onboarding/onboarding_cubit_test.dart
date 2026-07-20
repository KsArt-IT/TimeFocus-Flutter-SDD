import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/notifications/data/datasources/notification_permission_service.dart';
import 'package:timefocus/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:timefocus/features/settings/domain/entities/user_settings_entity.dart';
import 'package:timefocus/features/settings/domain/repositories/user_settings_repository.dart';

class _MockUserSettingsRepository extends Mock implements UserSettingsRepository {}

class _MockNotificationPermissionService extends Mock implements NotificationPermissionService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const UserSettingsEntity());
  });

  group('OnboardingCubit', () {
    late _MockUserSettingsRepository repository;
    late _MockNotificationPermissionService permissionService;

    setUp(() {
      repository = _MockUserSettingsRepository();
      permissionService = _MockNotificationPermissionService();
      when(
        () => repository.get(),
      ).thenAnswer((_) async => const Result.success(UserSettingsEntity()));
      when(() => repository.save(any())).thenAnswer((_) async => const Result.success(null));
    });

    blocTest<OnboardingCubit, OnboardingState>(
      'nextStep/previousStep move within [0, totalSteps - 1]',
      build: () => OnboardingCubit(repository, permissionService),
      act: (cubit) => cubit
        ..previousStep() // no-op, already at 0
        ..nextStep()
        ..nextStep()
        ..nextStep(), // no-op, already at last step
      expect: () => [
        const OnboardingState(step: 1),
        const OnboardingState(step: 2),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'setName updates draft name without touching persistence',
      build: () => OnboardingCubit(repository, permissionService),
      act: (cubit) => cubit.setName('Alex'),
      expect: () => [const OnboardingState(name: 'Alex')],
      verify: (_) => verifyNever(() => repository.save(any())),
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'skip completes onboarding without recording a name (FR-044)',
      build: () => OnboardingCubit(repository, permissionService),
      act: (cubit) async {
        cubit.setName('Alex');
        await cubit.skip();
      },
      verify: (cubit) {
        expect(cubit.state.completed, isTrue);
        final saved =
            verify(() => repository.save(captureAny())).captured.single as UserSettingsEntity;
        expect(saved.onboardingCompleted, isTrue);
        expect(saved.name, isEmpty);
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'finish completes onboarding and records the trimmed name',
      build: () => OnboardingCubit(repository, permissionService),
      act: (cubit) async {
        cubit.setName('  Alex  ');
        await cubit.finish();
      },
      verify: (cubit) {
        expect(cubit.state.completed, isTrue);
        final saved =
            verify(() => repository.save(captureAny())).captured.single as UserSettingsEntity;
        expect(saved.onboardingCompleted, isTrue);
        expect(saved.name, 'Alex');
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'requestNotificationPermission disables notifications on refusal (FR-036)',
      build: () => OnboardingCubit(repository, permissionService),
      setUp: () => when(() => permissionService.request()).thenAnswer((_) async => false),
      act: (cubit) => cubit.requestNotificationPermission(),
      expect: () => [
        const OnboardingState(requestingPermission: true),
        const OnboardingState(),
      ],
      verify: (_) {
        final saved =
            verify(() => repository.save(captureAny())).captured.single as UserSettingsEntity;
        expect(saved.reminderRequest, isTrue);
        expect(saved.notificationsEnabled, isFalse);
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'requestNotificationPermission keeps notifications enabled on grant',
      build: () => OnboardingCubit(repository, permissionService),
      setUp: () => when(() => permissionService.request()).thenAnswer((_) async => true),
      act: (cubit) => cubit.requestNotificationPermission(),
      verify: (_) {
        final saved =
            verify(() => repository.save(captureAny())).captured.single as UserSettingsEntity;
        expect(saved.notificationsEnabled, isTrue);
      },
    );
  });
}
