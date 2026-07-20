import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timefocus/core/di/injection.dart';
import 'package:timefocus/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:timefocus/gen/app_localizations.dart';

/// T084: fully skippable first-run flow — feature overview, optional name,
/// notification permission request with graceful refusal (FR-036/044).
/// Completion is picked up by the router redirect (T085) once
/// onboardingCompleted flips in the Drift stream — no manual navigation here.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnboardingCubit>(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            final cubit = context.read<OnboardingCubit>();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!state.completed)
                        TextButton(
                          onPressed: cubit.skip,
                          child: Text(l10n.onboardingSkip),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (state.step) {
                    0 => const _WelcomeStep(),
                    1 => const _NameStep(),
                    _ => const _NotificationStep(),
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _StepControls(state: state, cubit: cubit),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepControls extends StatelessWidget {
  const _StepControls({required this.state, required this.cubit});

  final OnboardingState state;
  final OnboardingCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLastStep = state.step >= OnboardingCubit.totalSteps - 1;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < OnboardingCubit.totalSteps; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: i == state.step
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
        ),
        if (state.step > 0)
          TextButton(
            onPressed: cubit.previousStep,
            child: Text(l10n.back),
          ),
        FilledButton(
          onPressed: state.requestingPermission
              ? null
              : (isLastStep ? cubit.finish : cubit.nextStep),
          child: Text(isLastStep ? l10n.onboardingStart : l10n.next),
        ),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final features = [
      (Icons.timer_outlined, l10n.navTracker),
      (Icons.timer, l10n.settingsPomodoro),
      (Icons.local_drink_outlined, l10n.settingsWater),
      (Icons.calendar_today_outlined, l10n.navSchedule),
      (Icons.history, l10n.navHistory),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingWelcomeTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l10n.onboardingWelcomeSubtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          for (final (icon, label) in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Text(label, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<OnboardingCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingNameTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.onboardingNameHint),
            onChanged: cubit.setName,
          ),
        ],
      ),
    );
  }
}

class _NotificationStep extends StatelessWidget {
  const _NotificationStep();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.permissionNotificationTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l10n.permissionNotificationBody, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: state.requestingPermission ? null : cubit.requestNotificationPermission,
                child: Text(l10n.requestNotificationPermission),
              ),
            ],
          ),
        );
      },
    );
  }
}
