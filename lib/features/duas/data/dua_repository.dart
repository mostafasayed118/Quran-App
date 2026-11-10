import '../../../core/utils/cached_loader.dart';
import '../domain/duas_models.dart';

// Compat: existing importers of this file keep resolving [DuaEntry], which
// now lives in domain/ so presentation stays off the data layer.
export '../domain/duas_models.dart';

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
