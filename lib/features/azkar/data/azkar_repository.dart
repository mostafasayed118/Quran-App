import '../../../core/utils/arabic_search.dart';
import '../../../core/utils/cached_loader.dart';
import '../domain/azkar_models.dart';

// Compat: existing importers of this file keep resolving the DTOs, which
// now live in [azkar_models.dart] so presentation stays off the data layer.
export '../domain/azkar_models.dart';

/// Reads the bundled azkar catalog and searches it locally.
class AzkarRepository {
  AzkarRepository({required Future<Map<String, dynamic>> Function() loader})
      : _loader = loader;

  final Future<Map<String, dynamic>> Function() _loader;

  /// Default maximum number of matches returned by [search].
  static const int searchLimit = 50;

  late final CachedLoader<List<AzkarCollection>> _collections =
      CachedLoader(_load);

  /// The catalog normalized once, in catalog order. Rebuilt only when the
  /// loader hands over a new list (it is cached, so in practice once).
  List<_AzkarSearchEntry>? _searchIndex;

  /// All collections; the catalog is loaded once and cached.
  Future<List<AzkarCollection>> collections() {
    return _collections.load();
  }

  /// Local, normalization-aware search over every collection name and item
  /// text. Bounded to [limit] hits with a [AzkarSearchResults.hasMore] flag;
  /// an empty query yields no hits.
  Future<AzkarSearchResults> search(String query,
      {int limit = searchLimit}) async {
    // Normalize the query ONCE; the loop below reuses it for every entry.
    final prepared = prepareQuery(query);
    if (prepared.isEmpty) {
      return const AzkarSearchResults(hits: [], hasMore: false);
    }
    final collections = await _collections.load();
    final entries = _searchIndex ??= [
      for (final collection in collections)
        for (var i = 0; i < collection.items.length; i++)
          _AzkarSearchEntry(
            collection: collection,
            itemIndex: i,
            text: normalizeArabic(collection.items[i].text).toLowerCase(),
            nameAr: normalizeArabic(collection.nameAr).toLowerCase(),
            nameEn: normalizeArabic(collection.nameEn).toLowerCase(),
          ),
    ];
    final hits = <AzkarSearchHit>[];
    var hasMore = false;
    for (final entry in entries) {
      if (matchesPrepared(entry.text, prepared) ||
          matchesPrepared(entry.nameAr, prepared) ||
          matchesPrepared(entry.nameEn, prepared)) {
        if (hits.length == limit) {
          hasMore = true;
          break;
        }
        hits.add(AzkarSearchHit(
          collection: entry.collection,
          itemIndex: entry.itemIndex,
        ));
      }
    }
    return AzkarSearchResults(hits: hits, hasMore: hasMore);
  }

  Future<List<AzkarCollection>> _load() async {
    final root = await _loader();
    final raw = (root['collections'] as List).cast<Map<String, dynamic>>();
    return [for (final collection in raw) AzkarCollection.fromJson(collection)];
  }
}

/// One normalized search row; the collection/item pair is what a hit needs.
class _AzkarSearchEntry {
  const _AzkarSearchEntry({
    required this.collection,
    required this.itemIndex,
    required this.text,
    required this.nameAr,
    required this.nameEn,
  });

  final AzkarCollection collection;
  final int itemIndex;
  final String text;
  final String nameAr;
  final String nameEn;
}
