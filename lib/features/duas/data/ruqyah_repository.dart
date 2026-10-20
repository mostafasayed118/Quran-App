import '../../../core/utils/cached_loader.dart';

/// One ruqyah item: either a Quran passage or a written ruqyah.
class RuqyahEntry {
  const RuqyahEntry({
    required this.id,
    required this.kind,
    this.surahId,
    this.fromAyah,
    this.toAyah,
    this.text,
    this.count = 1,
    this.reference,
  });

  /// Stable id of the item.
  final String id;

  /// 'quran' (range reference — text resolved from the bundled DB) or 'dhikr'.
  final String kind;

  /// Surah of the passage, for Quran-based items.
  final int? surahId;

  /// First ayah of the passage.
  final int? fromAyah;

  /// Last ayah of the passage.
  final int? toAyah;

  /// Written ruqyah text; null for Quran-based items.
  final String? text;

  /// How many times it should be recited.
  final int count;

  /// Optional source reference for the item.
  final String? reference;

  /// True when the item quotes the Quran instead of written ruqyah.
  bool get isQuran => kind == 'quran';

  factory RuqyahEntry.fromJson(Map<String, dynamic> json) => RuqyahEntry(
        id: json['id'] as String,
        kind: json['kind'] as String,
        surahId: (json['surahId'] as num?)?.toInt(),
        fromAyah: (json['fromAyah'] as num?)?.toInt(),
        toAyah: (json['toAyah'] as num?)?.toInt(),
        text: json['text'] as String?,
        count: (json['count'] as int?) ?? 1,
        reference: json['reference'] as String?,
      );
}

/// Reads the bundled ruqyah catalog.
class RuqyahRepository {
  RuqyahRepository({
    required Future<List<Map<String, dynamic>>> Function() loader,
  }) : _loader = loader;

  final Future<List<Map<String, dynamic>>> Function() _loader;

  late final CachedLoader<List<RuqyahEntry>> _entries = CachedLoader(_load);

  /// All items; the catalog is loaded once and cached.
  Future<List<RuqyahEntry>> entries() {
    return _entries.load();
  }

  Future<List<RuqyahEntry>> _load() async {
    final raw = await _loader();
    return [for (final row in raw) RuqyahEntry.fromJson(row)];
  }
}
