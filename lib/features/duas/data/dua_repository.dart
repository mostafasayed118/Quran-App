import '../../../core/utils/cached_loader.dart';

/// One supplication with its category and repetition count.
class DuaEntry {
  const DuaEntry({
    required this.id,
    required this.categoryAr,
    required this.text,
    this.reference,
    this.count = 1,
  });

  /// Stable id of the dua.
  final String id;

  /// Arabic category name the dua belongs to.
  final String categoryAr;

  /// Arabic text of the dua.
  final String text;

  /// Optional source reference for the dua.
  final String? reference;

  /// How many times it should be recited.
  final int count;

  factory DuaEntry.fromJson(Map<String, dynamic> json) => DuaEntry(
        id: json['id'] as String,
        categoryAr: json['categoryAr'] as String,
        text: json['text'] as String,
        reference: json['reference'] as String?,
        count: (json['count'] as int?) ?? 1,
      );
}

/// Reads the bundled duas catalog.
class DuaRepository {
  DuaRepository({
    required Future<List<Map<String, dynamic>>> Function() loader,
  }) : _loader = loader;

  final Future<List<Map<String, dynamic>>> Function() _loader;

  late final CachedLoader<List<DuaEntry>> _entries = CachedLoader(_load);

  /// All duas; the catalog is loaded once and cached.
  Future<List<DuaEntry>> entries() {
    return _entries.load();
  }

  Future<List<DuaEntry>> _load() async {
    final raw = await _loader();
    return [for (final row in raw) DuaEntry.fromJson(row)];
  }

  /// Duas of one category, matched on the Arabic category name.
  Future<List<DuaEntry>> byCategory(String categoryAr) async {
    final all = await entries();
    return [
      for (final entry in all)
        if (entry.categoryAr == categoryAr) entry,
    ];
  }

  /// Distinct Arabic category names, in catalog order.
  Future<List<String>> categories() async {
    final all = await entries();
    final seen = <String>{};
    return [
      for (final entry in all)
        if (seen.add(entry.categoryAr)) entry.categoryAr,
    ];
  }
}
