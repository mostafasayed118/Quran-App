/// One downloadable library pack (tafsir, translation or hadith) as declared
/// by the bundled or remote catalog manifest. Pure model + parse/validate —
/// no storage, no isolate.
library;

/// Library content-pack catalog (bundled, curated, version-pinned).
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

  /// Single-file kinds only (translation/hadith, or a tafsir edition served
  /// as one file): one probed CDN URL.
  final String? sourceUrl;

  /// Per-surah tafsir only: per-surah file URL with the `{n}` placeholder
  /// (n = surah number 1..fileCount, plain `n.json`, not zero-padded).
  final String? urlTemplate;

  /// Per-surah tafsir only: number of per-surah files (114 for real packs).
  final int? fileCount;

  /// Single-file kinds only: lowercase-hex sha256 of the exact served body,
  /// verified before promotion when present. Absent = shape sniff only.
  final String? sha256;

  /// Per-surah tafsir only: lowercase-hex sha256 per surah file in `{n}`
  /// order (index 0 = surah 1). Verified before decode/merge when present.
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
      final hasTemplate = urlTemplate != null &&
          urlTemplate.isNotEmpty &&
          fileCount != null &&
          fileCount > 0;
      final hasSingleFile = sourceUrl != null && sourceUrl.isNotEmpty;
      if (!hasTemplate && !hasSingleFile) {
        throw const FormatException(
            'tafsir pack requires urlTemplate/fileCount or sourceUrl');
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
