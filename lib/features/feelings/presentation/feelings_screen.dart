import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_yahdi/core/theme/app_colors.dart';
import 'package:quran_yahdi/core/theme/app_radius.dart';
import 'package:quran_yahdi/core/theme/app_spacing.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/core/widgets/app_content_frame.dart';
import 'package:quran_yahdi/core/widgets/error_pane.dart';
import 'package:quran_yahdi/core/widgets/loading_and_error_views.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import '../domain/feeling.dart';
import 'feelings_cubit.dart';
import 'feelings_icons.dart';
import 'feelings_state.dart';

/// Q43 — feelings picker.
class FeelingsScreen extends StatelessWidget {
  const FeelingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.feelingsTitle)),
      body: AppContentFrame(
        child: BlocBuilder<FeelingsCubit, FeelingsState>(
          builder: (context, state) => switch (state) {
            FeelingsLoading() => const LoadingView(),
            FeelingsFailed() => errorPane(
              loc,
              onRetry: context.read<FeelingsCubit>().start,
            ),
            FeelingsReady(:final feelings, :final savedCount) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(loc.feelingsSubtitle),
                const SizedBox(height: AppSpacing.lg),
                _HeroCard(verse: FeelingsCatalog.heroVerse),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.feelingsSectionTitle),
                    Text(loc.feelingsCount(feelings.length)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  children: [
                    for (final feeling in feelings)
                      _FeelingTile(
                        icon: feelingIcon(feeling.iconName),
                        label: _feelingName(loc, feeling.key.value),
                        onTap: () =>
                            context.push(feelingsVersesPath(feeling.key.value)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(loc.feelingsFooterNote),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.feelingsSaved),
                  icon: const Icon(Icons.bookmark_border),
                  label: Text(loc.feelingsSavedCount(savedCount)),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

String _feelingName(AppLocalizations loc, String key) => switch (key) {
  'qalaq' => loc.feelingQalaq,
  'huzn' => loc.feelingHuzn,
  'wahda' => loc.feelingWahda,
  'hayra' => loc.feelingHayra,
  'khawf' => loc.feelingKhawf,
  'ghadab' => loc.feelingGhadab,
  'imtinam' => loc.feelingImtinam,
  _ => loc.feelingAmal,
};

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.verse});

  final FeelingVerse verse;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.mushafCardTop, AppColors.mushafCardBottom],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            loc.feelingsAyahOfDay,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppColors.mushafCardAccent),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            verse.excerpt,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.mushafCardInk,
              fontFamily: 'HafsSmart',
            ),
          ),
          Text(
            loc.feelingsRefLine(loc.feelingsHeroSurah, verse.ayah),
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.mushafCardMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: () => context.push(
              feelingsVersePath(
                verse.surah,
                verse.ayah,
                FeelingsCatalog.qalaq.key.value,
              ),
            ),
            child: Text(loc.feelingsReadAyah),
          ),
        ],
      ),
    );
  }
}

class _FeelingTile extends StatelessWidget {
  const _FeelingTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(label),
          ],
        ),
      ),
    ),
  );
}
