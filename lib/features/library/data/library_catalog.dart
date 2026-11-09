import '../../../core/utils/cached_loader.dart';
import '../domain/library_pack.dart';

// Compat: existing importers of this file keep resolving the pack model,
// which now lives in domain/ so presentation stays off the data layer.
export '../domain/library_pack.dart'
    show LibraryPackKind, LibraryPackInfo, kindFor;

/// Library content-pack catalog (bundled, curated, version-pinned).
///
/// `CatalogSource` is the Supabase thin-layer seam locked in the W6 plan:
/// the bundled JSON catalog IS the v1 default source; a future remote
/// Supabase manifest implements the same contract. The intended remote
/// shape is a UTF-8 JSON object `{"packs": [ ...same pack objects... ]}`
/// served from the owner's Supabase project; when it exists, only a new
/// `CatalogSource` implementation is added here — the repositories, the
/// downloader and the UI keep consuming this seam unchanged.

/// The integrity contract for a catalog pack, per kind.
///
/// Every pack the catalog serves must declare its integrity hashes: a pack
/// served without them would silently degrade to shape-sniff-only at
/// download time. The bundled manifest and a remote manifest go through the
/// same gate - [requirePinnedCatalogEntries].
///
/// Returns null when the pack is fully pinned, or a diagnostic naming the
/// missing hashes.
String? catalogIntegrityGap(LibraryPackInfo pack) {
  switch (pack.kind) {
    case LibraryPackKind.tafsir:
      if (pack.urlTemplate == null) {
        return pack.sha256 == null ? 'requires a sha256 hash' : null;
      }
      final hashes = pack.sha256PerSurah;
      if (hashes == null ||
          (pack.fileCount != null && hashes.length != pack.fileCount)) {
        return 'requires sha256PerSurah covering its ${pack.fileCount} files';
      }
      return null;
    case LibraryPackKind.translation:
    case LibraryPackKind.hadith:
      return pack.sha256 == null ? 'requires a sha256 hash' : null;
  }
}

/// Throws a [FormatException] when [pack] is not fully integrity-pinned.
void _requirePinned(LibraryPackInfo pack) {
  final gap = catalogIntegrityGap(pack);
  if (gap != null) {
    throw FormatException('catalog pack "${pack.id}" $gap');
  }
}

/// Enforces the integrity contract on a raw catalog manifest.
///
/// This is the single gate every catalog manifest goes through: every entry
/// is parsed and checked against
/// [catalogIntegrityGap], and a pack served without its hashes is rejected
/// with a [FormatException] instead of degrading to shape-sniff-only at
/// download time. Malformed entries are left alone here - the catalog
/// source drops those, as it always has.
void requirePinnedCatalogEntries(List<Map<String, dynamic>> entries) {
  for (final entry in entries) {
    final LibraryPackInfo pack;
    try {
      pack = LibraryPackInfo.fromJson(entry);
    } on FormatException {
      continue;
    }
    _requirePinned(pack);
  }
}

/// The catalog-manifest seam (see the library doc comment above).
abstract class CatalogSource {
  /// Every pack the source offers.
  Future<List<LibraryPackInfo>> all();

  /// The pack with the given id, or null when the source has none.
  Future<LibraryPackInfo?> byId(String id) async {
    for (final pack in await all()) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}

/// A catalog source reading the JSON bundled with the app.
class BundledCatalogSource extends CatalogSource {
  BundledCatalogSource({required this.loader});

  /// Loads the raw catalog JSON; injected so tests can serve their own.
  final Future<List<Map<String, dynamic>>> Function() loader;

  late final CachedLoader<List<LibraryPackInfo>> _packs = CachedLoader(_load);

  @override
  Future<List<LibraryPackInfo>> all() {
    return _packs.load();
  }

  Future<List<LibraryPackInfo>> _load() async {
    final raw = await loader();
    final packs = <LibraryPackInfo>[];
    for (final entry in raw) {
      try {
        packs.add(LibraryPackInfo.fromJson(entry));
      } on FormatException {
        // Malformed catalog entries are rejected, never crash the app.
      }
    }
    return packs;
  }
}
