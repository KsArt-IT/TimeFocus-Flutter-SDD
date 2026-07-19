import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timefocus/core/result/result.dart';
import 'package:timefocus/features/settings/domain/entities/user_settings_entity.dart';
import 'package:timefocus/features/settings/domain/repositories/user_settings_repository.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:timefocus/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:timefocus/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:timefocus/features/tracker/domain/entities/action_name_entity.dart';
import 'package:timefocus/features/tracker/domain/repositories/action_name_repository.dart';
import 'package:timefocus/shared/enums/app_theme_mode.dart';

class _MockUserSettingsRepository extends Mock implements UserSettingsRepository {}

class _MockActionNameRepository extends Mock implements ActionNameRepository {}

const _action = ActionNameEntity(id: 1, name: 'Work', color: 0xFF000000, icon: 0);

void main() {
  setUpAll(() {
    registerFallbackValue(const UserSettingsEntity());
  });

  group('AppSettingsCubit', () {
    late _MockUserSettingsRepository repository;
    late StreamController<UserSettingsEntity> controller;

    setUp(() {
      repository = _MockUserSettingsRepository();
      // Broadcast + subscribed-before-any-add (constructor subscribes
      // synchronously in build()) — nothing emitted in setUp is lost.
      controller = StreamController<UserSettingsEntity>.broadcast();
      addTearDown(controller.close);
      when(() => repository.watch()).thenAnswer((_) => controller.stream);
      when(() => repository.save(any())).thenAnswer((invocation) async {
        controller.add(invocation.positionalArguments.first as UserSettingsEntity);
        return const Result.success(null);
      });
    });

    blocTest<AppSettingsCubit, AppSettingsState>(
      'starts unready with defaults, then picks up the Drift stream value',
      build: () => AppSettingsCubit(repository),
      act: (cubit) => controller.add(const UserSettingsEntity(name: 'from stream')),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state.ready, isTrue);
        expect(cubit.state.settings.name, 'from stream');
      },
    );

    blocTest<AppSettingsCubit, AppSettingsState>(
      'setThemeMode instantly persists — no debounce, no confirmation step',
      build: () => AppSettingsCubit(repository),
      act: (cubit) async {
        controller.add(const UserSettingsEntity());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await cubit.setThemeMode(AppThemeMode.dark);
      },
      verify: (_) {
        verify(
          () => repository.save(
            any(that: predicate<UserSettingsEntity>((s) => s.themeMode == AppThemeMode.dark)),
          ),
        ).called(1);
      },
    );

    blocTest<AppSettingsCubit, AppSettingsState>(
      'setLanguage("system") is the system-locale sentinel (locale getter returns null)',
      build: () => AppSettingsCubit(repository),
      act: (cubit) async {
        controller.add(const UserSettingsEntity());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await cubit.setLanguage('system');
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state.locale, isNull);
      },
    );

    blocTest<AppSettingsCubit, AppSettingsState>(
      'setLanguage("ru") resolves to a concrete Locale',
      build: () => AppSettingsCubit(repository),
      act: (cubit) async {
        controller.add(const UserSettingsEntity());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await cubit.setLanguage('ru');
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state.locale?.languageCode, 'ru');
      },
    );
  });

  group('SettingsCubit', () {
    late _MockActionNameRepository actions;

    setUp(() {
      actions = _MockActionNameRepository();
    });

    blocTest<SettingsCubit, SettingsState>(
      'subscribes to watchAll and surfaces the activity list',
      setUp: () => when(() => actions.watchAll()).thenAnswer((_) => Stream.value([_action])),
      build: () => SettingsCubit(actions),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state, const SettingsState.loaded([_action]));
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'setArchived delegates straight to the repository',
      setUp: () {
        when(() => actions.watchAll()).thenAnswer((_) => Stream.value([_action]));
        when(() => actions.setArchived(1, archived: true)).thenAnswer(
          (_) async => const Result.success(null),
        );
      },
      build: () => SettingsCubit(actions),
      act: (cubit) => cubit.setArchived(1, archived: true),
      verify: (_) {
        verify(() => actions.setArchived(1, archived: true)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'delete delegates straight to the repository',
      setUp: () {
        when(() => actions.watchAll()).thenAnswer((_) => Stream.value([_action]));
        when(() => actions.delete(1)).thenAnswer((_) async => const Result.success(null));
      },
      build: () => SettingsCubit(actions),
      act: (cubit) => cubit.delete(1),
      verify: (_) {
        verify(() => actions.delete(1)).called(1);
      },
    );
  });
}
