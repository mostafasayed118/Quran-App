/// Bundled azkar catalog domain models.
///
/// The data layer (repository) and the presentation layer (freezed states)
/// both depend on these; they carry no storage concerns.
library;

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
