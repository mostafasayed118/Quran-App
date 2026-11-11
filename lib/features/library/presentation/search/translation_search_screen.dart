import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/utils/text_direction.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'translation_search_cubit.dart';
import 'translation_search_state.dart';

/// Searches the installed translations and opens a hit in the reader.
class TranslationSearchScreen extends StatefulWidget {
  /// Creates the screen.
  const TranslationSearchScreen({super.key});

  @override
  State<TranslationSearchScreen> createState() =>
      _TranslationSearchScreenState();
}

class _TranslationSearchScreenState extends State<TranslationSearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<TranslationSearchCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.translationSearchTitle)),
      body: AppContentFrame(
        child: BlocBuilder<TranslationSearchCubit, TranslationSearchState>(
          builder: (context, state) => switch (state) {
            TranslationSearchLoading() => const LoadingView(),
            TranslationSearchFailed() => errorPane(loc, onRetry: cubit.start),
            TranslationSearchReady(:final hasPacks) when !hasPacks =>
              EmptyState(
                loc.translationSearchNoPacks,
                icon: Icons.translate,
                actionLabel: loc.library,
                onAction: () => context.pop(),
              ),
            TranslationSearchReady(
              :final query,
              :final hits,
              :final total,
            ) =>
              _Results(
                controller: _controller,
                query: query,
                hits: hits,
                total: total,
              ),
          },
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.controller,
    required this.query,
    required this.hits,
    required this.total,
  });

  final TextEditingController controller;
  final String query;
  final List<TranslationHit> hits;
  final int total;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<TranslationSearchCubit>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: loc.translationSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: cubit.setQuery,
          ),
        ),
        if (query.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  loc.translationSearchEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else if (hits.isEmpty)
          Expanded(
            child: EmptyState(
              loc.translationSearchNoResults,
              icon: Icons.search_off,
            ),
          )
        else
          Expanded(
            child: Builder(builder: (context) {
              final truncated = hits.length < total;
              return ListView.builder(
                padding: EdgeInsets.only(bottom: appBottomInset(context)),
                itemCount: hits.length + 1 + (truncated ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        loc.translationSearchResults(loc.number(total)),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    );
                  }
                  if (truncated && index == hits.length + 1) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        loc.translationSearchTruncated(
                          loc.number(hits.length),
                          loc.number(total),
                        ),
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    );
                  }
                  final hit = hits[index - 1];
                  final label = hit.surahName.isEmpty
                      ? loc.surahBadge(loc.number(hit.surahId))
                      : hit.surahName;
                  return ListTile(
                    title: Text('$label · ${loc.number(hit.ayah)}'),
                    subtitle: Text(
                      hit.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textDirection: isArabicText(hit.text)
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                    ),
                    onTap: () => context.push(
                      quranReaderPath(surah: hit.surahId, ayah: hit.ayah),
                    ),
                  );
                },
              );
            }),
          ),
      ],
    );
  }
}
