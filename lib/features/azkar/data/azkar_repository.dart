import '../../../core/utils/arabic_search.dart';
import '../../../core/utils/cached_loader.dart';

/// One remembrance (dhikr) with its repetition count.
class AzkarItem {
  const AzkarItem({
    required this.text,
    this.count = 1,
    this.virtue,
    this.reference,
  });

  /// Arabic text of the remembrance.
  final String text;

  /// How many times it should be repeated.
  final int count;

  /// Optional virtue/reward of the remembrance.
  final String? virtue;

  /// Optional source reference for the remembrance.
  final String? reference;

  factory AzkarItem.fromJson(Map<String, dynamic> json) => AzkarItem(
        text: json['text'] as String,
        count: (json['count'] as int?) ?? 1,
        virtue: json['virtue'] as String?,
        reference: json['reference'] as String?,
      );
}

/// A named group of remembrances (e.g. morning/evening).
class AzkarCollection {
  const AzkarCollection({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.items,
  });

  /// Stable id of the collection.
  final String id;

  /// Arabic title of the collection.
  final String nameAr;

  /// English title of the collection.
  final String nameEn;

  /// Remembrances of the collection, in display order.
  final List<AzkarItem> items;

  factory AzkarCollection.fromJson(Map<String, dynamic> json) =>
      AzkarCollection(
        id: json['id'] as String,
        nameAr: json['nameAr'] as String,
        nameEn: json['nameEn'] as String,
        items: [
          for (final item
              in (json['items'] as List).cast<Map<String, dynamic>>())
            AzkarItem.fromJson(item),
        ],
      );
}

/// One search match: a collection plus the index of the item.
class AzkarSearchHit {
  const AzkarSearchHit({required this.collection, required this.itemIndex});

  /// Collection the match was found in.
  final AzkarCollection collection;

  /// Index of the matched item inside [collection].
  final int itemIndex;

  AzkarItem get item => collection.items[itemIndex];
}

/// A page of search matches.
class AzkarSearchResults {
  const AzkarSearchResults({required this.hits, required this.hasMore});

  /// Matches of the current query, in order.
  final List<AzkarSearchHit> hits;

  /// True when more matches exist beyond this page.
  final bool hasMore;
}

/// Reads the bundled azkar catalog and searches it locally.
class AzkarRepository {
  AzkarRepository({required Future<Map<String, dynamic>> Function() loader})
      : _loader = loader;

  final Future<Map<String, dynamic>> Function() _loader;

  /// Default maximum number of matches returned by [search].
  static const int searchLimit = 50;

  late final CachedLoader<List<AzkarCollection>> _collections =
      CachedLoader(_load);

  /// All collections; the catalog is loaded once and cached.
  Future<List<AzkarCollection>> collections() {
    return _collections.load();
  }

  /// Local, normalization-aware search over every collection name and item
  /// text. Bounded to [limit] hits with a [AzkarSearchResults.hasMore] flag;
  /// an empty query yields no hits.
  Future<AzkarSearchResults> search(String query,
      {int limit = searchLimit}) async {
    if (normalizeArabic(query).isEmpty) {
      return const AzkarSearchResults(hits: [], hasMore: false);
    }
    final collections = await _collections.load();
    final hits = <AzkarSearchHit>[];
    var hasMore = false;
    for (final collection in collections) {
      for (var i = 0; i < collection.items.length; i++) {
        final item = collection.items[i];
        if (matchesQuery(item.text, query) ||
            matchesQuery(collection.nameAr, query) ||
            matchesQuery(collection.nameEn, query)) {
          if (hits.length == limit) {
            hasMore = true;
            break;
          }
          hits.add(AzkarSearchHit(collection: collection, itemIndex: i));
        }
      }
      if (hasMore) break;
    }
    return AzkarSearchResults(hits: hits, hasMore: hasMore);
  }

  Future<List<AzkarCollection>> _load() async {
    final root = await _loader();
    final raw = (root['collections'] as List).cast<Map<String, dynamic>>();
    return [for (final collection in raw) AzkarCollection.fromJson(collection)];
  }
}
