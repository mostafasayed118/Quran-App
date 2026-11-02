import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'onboarding_cubit.dart';
import 'onboarding_state.dart';

/// The first-run setup: pick a city, allow reminders, start.
///
/// Deliberately a normal pushable route, not a boot gate: the app is usable
/// without it (Quran reading never needs a city), and Home advertises it until
/// the user finishes or skips.
class OnboardingScreen extends StatelessWidget {
  /// Creates the screen.
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          current is OnboardingReady &&
          current.completed &&
          (previous is! OnboardingReady || !previous.completed),
      listener: (context, state) {
        if (context.canPop()) context.pop();
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(loc.onboardingTitle),
          actions: [
            if (state is OnboardingReady && !state.completed)
              TextButton(
                onPressed: () => context.read<OnboardingCubit>().finish(),
                child: Text(loc.onboardingSkip),
              ),
          ],
        ),
        body: switch (state) {
          OnboardingLoading() => const LoadingView(),
          OnboardingReady(
            :final citySelected,
            :final cityName,
            :final remindersGranted,
          ) =>
            _Steps(
              citySelected: citySelected,
              cityName: cityName,
              remindersGranted: remindersGranted,
            ),
        },
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({
    required this.citySelected,
    required this.cityName,
    required this.remindersGranted,
  });

  final bool citySelected;
  final String? cityName;
  final bool remindersGranted;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<OnboardingCubit>();
    return ListView(
      padding: appScrollPadding(
        context,
        const EdgeInsets.all(AppSpacing.lg),
      ),
      children: [
        Text(loc.onboardingIntro, style: AppTheme.cardTitle),
        const SizedBox(height: AppSpacing.lg),
        _StepCard(
          icon: Icons.place_outlined,
          title: citySelected
              ? loc.onboardingCityDone(cityName ?? '')
              : loc.selectCity,
          done: citySelected,
          actionLabel: citySelected ? loc.onboardingChangeCity : null,
          onTap: () async {
            await context.push(AppRoutes.cityPicker);
            await cubit.refreshCity();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _StepCard(
          icon: Icons.notifications_active_outlined,
          title: remindersGranted
              ? loc.onboardingEnabled
              : loc.onboardingRemindersTitle,
          subtitle: loc.onboardingRemindersBody,
          done: remindersGranted,
          actionLabel: remindersGranted ? null : loc.onboardingAllow,
          onTap: cubit.requestReminders,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => cubit.finish(),
          child: Text(loc.onboardingStart),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.done,
    required this.onTap,
    this.actionLabel,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool done;

  /// Optional label for the inline action; null hides the action row (the
  /// whole card stays tappable).
  final String? actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: done ? colors.secondary : colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTheme.cardTitle),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!,
                              style: AppTheme.mutedFootnote(context)),
                        ],
                      ],
                    ),
                  ),
                  if (done)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: Icon(Icons.check_circle,
                          color: colors.secondary, size: 20),
                    ),
                  if (actionLabel != null)
                    Text(
                      actionLabel!,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
