import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:quran_yahdi/core/theme/app_spacing.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/core/widgets/app_content_frame.dart';
import 'package:quran_yahdi/core/widgets/error_pane.dart';
import 'package:quran_yahdi/core/widgets/loading_and_error_views.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'feeling_label.dart';
import 'feeling_verses_cubit.dart';
import 'feelings_reference.dart';
import 'feelings_state.dart';

/// Q44 — the two verses of one feeling.
class FeelingVersesScreen extends StatelessWidget {
  const FeelingVersesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: AppContentFrame(
        child: BlocBuilder<FeelingVersesCubit, FeelingVersesState>(
          builder: (context, state) => switch (state) {
            FeelingVersesLoading() => const LoadingView(),
            FeelingVersesFailed() => errorPane(
              loc,
              onRetry: context.read<FeelingVersesCubit>().start,
            ),
            FeelingVersesReady(:final feeling, :final verses) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  feelingLabel(loc, feeling.value),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  feeling.value == 'qalaq'
                      ? loc.feelingsQalaqSubtitle
                      : loc.feelingsGenericSubtitle,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final verse in verses)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            feelingReference(context, verse),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            verse.excerpt,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontFamily: 'HafsSmart'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: () => context.push(
                              feelingsVersePath(
                                verse.verse.surah,
                                verse.verse.ayah,
                                feeling.value,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back),
                            label: Text(loc.feelingsReadAndReflect),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.autorenew),
                  label: Text(loc.feelingsAnother),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}
