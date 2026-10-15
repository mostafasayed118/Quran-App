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
  });

  final String id;
  final LibraryPackKind kind;
  final String language;
  final String titleAr;
  final String titleEn;
  final String version;
  final double approxSizeMb;

  /// Single-file kinds only (translation/hadith): one probed CDN URL.
  final String? sourceUrl;

  /// Tafsir kind only: per-surah file URL with the `{n}` placeholder
  /// (n = surah number 1..fileCount, plain `n.json`, not zero-padded).
  final String? urlTemplate;

  /// Tafsir kind only: number of per-surah files (114 for real packs).
  final int? fileCount;

  factory LibraryPackInfo.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final kindRaw = json['kind'] as String?;
    final language = json['language'] as String?;
    final titleAr = json['titleAr'] as String?;
    final titleEn = json['titleEn'] as String?;
    final approx = json['approxSizeMb'] as num?;
    final version = json['version'] as String?;
    if (id == null ||
        id.isEmpty ||
        language == null ||
        language.isEmpty ||
        titleAr == null ||
        titleAr.isEmpty ||
        titleEn == null ||
        titleEn.isEmpty ||
        approx == null ||
        version == null ||
        version.isEmpty) {
      throw const FormatException('invalid library pack entry');
    }
    LibraryPackKind kind;
    try {
      kind = kindFor(kindRaw!);
    } on FormatException {
      rethrow;
    }
    final sourceUrl = json['sourceUrl'] as String?;
    final urlTemplate = json['urlTemplate'] as String?;
    final fileCount = json['fileCount'] as int?;
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
    );
  }
}

LibraryPackKind kindFor(String raw) {
  for (final k in LibraryPackKind.values) {
    if (k.name == raw) return k;
  }
  throw FormatException('unknown library pack kind: "$raw"');
}

/// The remote-manifest seam (see the library doc comment above).
abstract class CatalogSource {
  Future<List<LibraryPackInfo>> all();

  Future<LibraryPackInfo?> byId(String id) async {
    for (final pack in await all()) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}

class BundledCatalogSource extends CatalogSource {
  BundledCatalogSource({required this.loader});

  final Future<List<Map<String, dynamic>>> Function() loader;

  @override
  Future<List<LibraryPackInfo>> all() async {
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
