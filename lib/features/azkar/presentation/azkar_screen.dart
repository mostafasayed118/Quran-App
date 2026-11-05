import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/azkar_repository.dart';
import 'azkar_cubit.dart';
import 'azkar_state.dart';

/// Whether the azkar scaffold must rebuild for [current].
///
/// A counter tap (or a restart) emits the same reciting collection with new
/// `remaining` values; the rows own that (each card selects its own counter),
/// so rebuilding the whole scaffold per tap is pure cost. Every other
/// transition — a new session, browsing, a search result, a failure — rebuilds.
bool azkarScreenShouldRebuild(AzkarState previous, AzkarState current) {
  if (previous.runtimeType != current.runtimeType) return true;
  if (previous is AzkarReciting && current is AzkarReciting) {
    return !identical(previous.collection, current.collection);
  }
  return true;
}

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<AzkarCubit, AzkarState>(
      buildWhen: azkarScreenShouldRebuild,
      builder: (context, state) {
        final reciting = state is AzkarReciting;
        return PopScope(
          canPop: !reciting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && reciting) {
              context.read<AzkarCubit>().back();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const _AzkarTitle(),
              leading: const _AzkarBackButton(),
              actions: [
                if (reciting)
                  IconButton(
                    tooltip: loc.azkarRestart,
                    icon: const Icon(Icons.restart_alt),
                    onPressed: context.read<AzkarCubit>().restart,
                  ),
              ],
            ),
            body: switch (state) {
              AzkarLoading() => const LoadingView(),
              AzkarFailed() => errorPane(loc),
              AzkarBrowsing(
                :final collections,
                :final favorites,
                :final query,
                :final searchResults,
                :final searchHasMore,
              ) =>
                _BrowsingView(
                  collections: collections,
                  favorites: favorites,
                  query: query,
                  searchResults: searchResults,
                  searchHasMore: searchHasMore,
                ),
              AzkarReciting(:final collection) =>
                _RecitingList(collection: collection),
            },
          ),
        );
      },
    );
  }
}

class _AzkarTitle extends StatelessWidget {
  const _AzkarTitle();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<AzkarCubit, AzkarState>(
      builder: (context, state) => switch (state) {
        AzkarReciting(:final collection) => Text(collection.nameAr),
        _ => Text(loc.azkar),
      },
    );
  }
}

class _AzkarBackButton extends StatelessWidget {
  const _AzkarBackButton();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<AzkarCubit, AzkarState>(
      builder: (context, state) {
        final reciting = state is AzkarReciting;
        return IconButton(
          tooltip: loc.backTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (reciting) {
              context.read<AzkarCubit>().back();
            } else {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }
}

class _BrowsingView extends StatelessWidget {
  const _BrowsingView({
    required this.collections,
    required this.favorites,
    required this.query,
    required this.searchResults,
    required this.searchHasMore,
  });

  final List<AzkarCollection> collections;
  final Set<String> favorites;
  final String query;
  final List<AzkarSearchHit> searchResults;
  final bool searchHasMore;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
          child: SearchField(
            hint: loc.azkarSearchPlaceholder,
            onChanged: context.read<AzkarCubit>().setSearchQuery,
          ),
        ),
        Expanded(
          child: query.isEmpty
              ? (collections.isEmpty
                  ? EmptyState(loc.noResults)
                  : ListView.builder(
                      padding: appScrollPadding(
                        context,
                        const EdgeInsets.all(AppSpacing.md),
                      ),
                      itemCount: collections.length,
                      itemBuilder: (context, i) => _CollectionTile(
                        collection: collections[i],
                        favorite: favorites.contains(collections[i].id),
                      ),
                    ))
              : _SearchResultsList(
                  results: searchResults,
                  hasMore: searchHasMore,
                ),
        ),
      ],
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({required this.results, required this.hasMore});

  final List<AzkarSearchHit> results;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (results.isEmpty) return EmptyState(loc.azkarSearchNoResults);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, AppSpacing.xs),
          child: Text(
            loc.azkarSearchResultsFor(loc.number(results.length)),
            style: AppTheme.mutedFootnote(context),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: appScrollPadding(
              context,
              const EdgeInsets.all(AppSpacing.md),
            ),
            itemCount: results.length + (hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == results.length) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    loc.azkarSearchMore(
                        loc.number(AzkarRepository.searchLimit)),
                    textAlign: TextAlign.center,
                    style: AppTheme.mutedFootnote(context),
                  ),
                );
              }
              return _SearchHitTile(hit: results[i]);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchHitTile extends StatelessWidget {
  const _SearchHitTile({required this.hit});

  final AzkarSearchHit hit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        title: Text(
          hit.item.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: QuranFonts.meQuran,
            fontSize: 16,
            height: 1.8,
          ),
        ),
        subtitle: Text(
          hit.collection.nameAr,
          textAlign: TextAlign.right,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        onTap: () => context.read<AzkarCubit>().open(hit.collection),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.collection, required this.favorite});

  final AzkarCollection collection;
  final bool favorite;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        title: Text(
          collection.nameAr,
          style: const TextStyle(
            fontFamily: QuranFonts.meQuran,
            fontSize: 19,
          ),
        ),
        subtitle: Text(collection.nameEn),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.azkarItemsCount(loc.number(collection.items.length)),
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
            IconButton(
              tooltip:
                  favorite ? loc.azkarFavoriteRemove : loc.azkarFavoriteAdd,
              icon: Icon(
                favorite ? Icons.star : Icons.star_border,
                color: favorite ? colors.secondary : colors.onSurfaceVariant,
              ),
              onPressed: () =>
                  context.read<AzkarCubit>().toggleFavorite(collection.id),
            ),
          ],
        ),
        onTap: () => context.read<AzkarCubit>().open(collection),
      ),
    );
  }
}

class _RecitingList extends StatelessWidget {
  const _RecitingList({required this.collection});

  /// The open session's collection — stable while counting, so the list itself
  /// is built once and each row subscribes to its own counter.
  final AzkarCollection collection;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: appScrollPadding(
        context,
        const EdgeInsets.all(AppSpacing.md),
      ),
      itemCount: collection.items.length,
      itemBuilder: (context, i) {
        final item = collection.items[i];
        // Per-row selector: a tap re-emits the whole state, but only the row
        // whose counter changed rebuilds.
        return BlocSelector<AzkarCubit, AzkarState, int>(
          selector: (state) =>
              state is AzkarReciting && i < state.remaining.length
                  ? state.remaining[i]
                  : item.count,
          builder: (context, remaining) =>
              _RecitingCard(item: item, remaining: remaining, index: i),
        );
      },
    );
  }
}

class _RecitingCard extends StatelessWidget {
  const _RecitingCard({
    required this.item,
    required this.remaining,
    required this.index,
  });

  final AzkarItem item;
  final int remaining;
  final int index;

  @override
  Widget build(BuildContext context) {
    final done = remaining == 0;
    final colors = Theme.of(context).colorScheme;
    return Opacity(
      // 0.45 dropped the completed body text to ~2.6:1. 0.8 keeps a clear
      // "done" affordance while the text remains readable.
      opacity: done ? 0.8 : 1,
      child: Card(
        color: done ? colors.surfaceContainerHighest : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          onTap: done
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  context.read<AzkarCubit>().tapItem(index);
                },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ZikrLine(item: item, remaining: remaining, done: done),
                if (item.virtue != null || item.reference != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      [
                        if (item.virtue case final virtue?) virtue,
                        if (item.reference case final reference?) reference,
                      ].join(' · '),
                      textAlign: TextAlign.right,
                      style: AppTheme.mutedFootnote(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZikrLine extends StatelessWidget {
  const _ZikrLine({
    required this.item,
    required this.remaining,
    required this.done,
  });

  final AzkarItem item;
  final int remaining;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            item.text,
            textAlign: TextAlign.right,
            // Long-form dhikr prose reads in the UI face; the mushaf face is
            // for Quran text (its word spacing and kashida suit a page).
            style: const TextStyle(
              fontFamily: QuranFonts.ui,
              fontSize: 17,
              height: 2.1,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? colors.secondary : colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check, size: 20)
              : Text(
                  loc.number(remaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
        ),
      ],
    );
  }
}
