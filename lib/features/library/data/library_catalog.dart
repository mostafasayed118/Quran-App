import '../../../core/utils/cached_loader.dart';

/// Library content-pack catalog (bundled, curated, version-pinned).
///
/// `CatalogSource` is the Supabase thin-layer seam locked in the W6 plan:
/// the bundled JSON catalog IS the v1 default source; a future remote
/// Supabase manifest implements the same contract. The intended remote
/// shape is a UTF-8 JSON object `{"packs": [ ...same pack objects... ]}`
/// served from the owner's Supabase project; when it exists, only a new
/// `CatalogSource` implementation is added here — the repositories, the
/// downloader and the UI keep consuming this seam unchanged.
enum LibraryPackKind { tafsir, translation, hadith }

/// Pack ids compose filesystem paths (`<root>/library/<id>.json`), so they
/// are restricted to a safe charset — this also guards the future remote
/// catalog manifest seam against path traversal.
final RegExp _packIdPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

/// Integrity hashes are lowercase-hex sha256 digests (64 chars).
final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

bool _isHttps(String? url) => url == null || url.startsWith('https://');

/// One downloadable library pack (tafsir, translation or hadith).
class LibraryPackInfo {
  const LibraryPackInfo({
    required this.id,
    required this.kind,
    required this.language,
    required this.titleAr,
    required this.titleEn,
    required this.approxSizeMb,
    required this.version,
    this.sourceUrl,
    this.urlTemplate,
    this.fileCount,
    this.sha256,
    this.sha256PerSurah,
  });

  /// Stable id of the pack.
  final String id;

  /// What the pack contains.
  final LibraryPackKind kind;

  /// Language of the pack content, e.g. `ar` or `en`.
  final String language;

  /// Arabic title.
  final String titleAr;

  /// English title.
  final String titleEn;

  /// Catalog version of the pack.
  final String version;

  /// Approximate download size in megabytes.
  final double approxSizeMb;

  /// Single-file kinds only (translation/hadith): one probed CDN URL.
  final String? sourceUrl;

  /// Tafsir kind only: per-surah file URL with the `{n}` placeholder
  /// (n = surah number 1..fileCount, plain `n.json`, not zero-padded).
  final String? urlTemplate;

  /// Tafsir kind only: number of per-surah files (114 for real packs).
  final int? fileCount;

  /// Single-file kinds only: lowercase-hex sha256 of the exact served body,
  /// verified before promotion when present. Absent = shape sniff only.
  final String? sha256;

  /// Tafsir kind only: lowercase-hex sha256 per surah file in `{n}` order
  /// (index 0 = surah 1). Verified before decode/merge when present.
  final List<String>? sha256PerSurah;

  factory LibraryPackInfo.fromJson(Map<String, dynamic> json) {
    final id = _requireString(json, 'id');
    if (!_packIdPattern.hasMatch(id)) {
      throw const FormatException('invalid library pack entry');
    }
    final kind = kindFor(_requireString(json, 'kind'));
    final language = _requireString(json, 'language');
    final titleAr = _requireString(json, 'titleAr');
    final titleEn = _requireString(json, 'titleEn');
    final version = _requireString(json, 'version');
    final approx = json['approxSizeMb'] as num?;
    if (approx == null) {
      throw const FormatException('invalid library pack entry');
    }
    final sourceUrl = json['sourceUrl'] as String?;
    final urlTemplate = json['urlTemplate'] as String?;
    final fileCount = json['fileCount'] as int?;
    _validatePackShape(
      kind,
      sourceUrl: sourceUrl,
      urlTemplate: urlTemplate,
      fileCount: fileCount,
    );
    return LibraryPackInfo(
      id: id,
      kind: kind,
      language: language,
      titleAr: titleAr,
      titleEn: titleEn,
      approxSizeMb: approx.toDouble(),
      version: version,
      sourceUrl: sourceUrl,
      urlTemplate: urlTemplate,
      fileCount: fileCount,
      sha256: _parseSha256(json['sha256']),
      sha256PerSurah: _parseSha256PerSurah(json['sha256PerSurah'], fileCount),
    );
  }
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key] as String?;
  if (value == null || value.isEmpty) {
    throw const FormatException('invalid library pack entry');
  }
  return value;
}

void _validatePackShape(
  LibraryPackKind kind, {
  required String? sourceUrl,
  required String? urlTemplate,
  required int? fileCount,
}) {
  if (!_isHttps(sourceUrl) || !_isHttps(urlTemplate)) {
    throw const FormatException('pack urls must be https');
  }
  switch (kind) {
    case LibraryPackKind.tafsir:
      if (urlTemplate == null ||
          urlTemplate.isEmpty ||
          fileCount == null ||
          fileCount <= 0) {
        throw const FormatException(
            'tafsir pack requires urlTemplate and fileCount');
      }
    case LibraryPackKind.translation:
    case LibraryPackKind.hadith:
      if (sourceUrl == null || sourceUrl.isEmpty) {
        throw FormatException('$kind pack requires sourceUrl');
      }
  }
}

String? _parseSha256(Object? raw) {
  if (raw == null) return null;
  if (raw is String && _sha256Pattern.hasMatch(raw)) return raw;
  throw const FormatException('invalid sha256 hash');
}

List<String>? _parseSha256PerSurah(Object? raw, int? fileCount) {
  if (raw == null) return null;
  if (raw is! List ||
      !raw.every((h) => h is String && _sha256Pattern.hasMatch(h))) {
    throw const FormatException('invalid sha256PerSurah hashes');
  }
  if (fileCount != null && raw.length != fileCount) {
    throw const FormatException('sha256PerSurah length must equal fileCount');
  }
  return raw.cast<String>();
}

/// Maps a raw catalog kind to a [LibraryPackKind]; unknown kinds throw.
LibraryPackKind kindFor(String raw) {
  for (final k in LibraryPackKind.values) {
    if (k.name == raw) return k;
  }
  throw FormatException('unknown library pack kind: "$raw"');
}

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
