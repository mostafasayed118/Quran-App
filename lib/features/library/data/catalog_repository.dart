import 'library_catalog.dart';

/// Read-side catalog API over the [CatalogSource] seam.
class CatalogRepository {
  CatalogRepository({required CatalogSource source}) : _source = source;

  final CatalogSource _source;

  /// All catalog packs, optionally filtered by kind.
  Future<List<LibraryPackInfo>> packs({LibraryPackKind? kind}) async {
    final all = await _source.all();
    if (kind == null) return all;
    return [
      for (final pack in all)
        if (pack.kind == kind) pack
    ];
  }

  /// The pack with the given id, or null when it is not in the catalog.
  Future<LibraryPackInfo?> byId(String id) => _source.byId(id);
}
