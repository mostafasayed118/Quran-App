import '../../../core/utils/cached_loader.dart';
import '../domain/asma_models.dart';

// Compat: existing importers of this file keep resolving [AsmaName], which
// now lives in domain/ so presentation stays off the data layer.
export '../domain/asma_models.dart';

/// Reads the bundled ninety-nine-names catalog.
class AsmaRepository {
  AsmaRepository({
    required Future<List<Map<String, dynamic>>> Function() loader,
  }) : _loader = loader;

  final Future<List<Map<String, dynamic>>> Function() _loader;

  late final CachedLoader<List<AsmaName>> _names = CachedLoader(_load);

  /// All names in order; the catalog is loaded once and cached.
  Future<List<AsmaName>> names() {
    return _names.load();
  }

  Future<List<AsmaName>> _load() async {
    final raw = await _loader();
    return [for (final row in raw) AsmaName.fromJson(row)]
      ..sort((a, b) => a.n.compareTo(b.n));
  }
}
