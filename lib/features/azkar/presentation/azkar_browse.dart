part of 'azkar_screen.dart';

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
            fontSize: AppType.bodyLarge,
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
            fontSize: AppType.titleLarge,
          ),
        ),
        subtitle: Text(collection.nameEn),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.azkarItemsCount(loc.number(collection.items.length)),
              style: TextStyle(
                fontSize: AppType.caption,
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
