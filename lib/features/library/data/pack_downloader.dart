import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'library_catalog.dart';

class PackFailure implements Exception {
  PackFailure(this.message);

  final String message;
  @override
  String toString() => 'PackFailure: $message';
}

/// Downloads and registers offline library packs.
///
/// Mirrors the AudioDownloader discipline: dio streaming, write-then-promote
/// (dot-part file), JSON-parse integrity sniff before promotion, measured
/// size + version in the InstalledPacks row, partial-file delete and NO row
/// on any failure.
///
/// Kind-aware install:
/// - translation/hadith: stream the single [LibraryPackInfo.sourceUrl] into
///   `<root>/library/<packId>.json`.
/// - tafsir: sequential GET loop over [LibraryPackInfo.urlTemplate]
///   (n = 1..fileCount, plain `n.json`), streaming the REAL per-surah
///   arrays verbatim into ONE documented wrapper
///   `{"pack":"<id>","tafsirs":[ <per-surah arrays verbatim>, ... ]}`;
///   any failed GET destroys the dot-part and installs no row.
class PackDownloader {
  PackDownloader(
    this._db, {
    Dio? dio,
    Future<Directory> Function()? libraryRootResolver,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(minutes: 2),
            )),
        _rootResolver = libraryRootResolver;

  final AppDatabase _db;
  final Dio _dio;
  final Future<Directory> Function()? _rootResolver;

  /// Decoded-pack cache: the read API is called per ayah-sheet open and per
  /// hadith page turn, and re-reading + re-decoding multi-MB pack files on
  /// the UI isolate per call froze the app. Keyed by packId; the only writers
  /// of pack files (install/uninstall) invalidate it.
  final Map<String, dynamic> _decodedCache = {};

  static const libraryFolderName = 'library';

  /// Guard against a lying/compromised host streaming unbounded bytes:
  /// allow up to 2x the declared size plus 64 KiB slack.
  static int _sizeCap(int expectedBytes) => expectedBytes * 2 + 65536;

  Future<Directory> _root() async {
    final resolver = _rootResolver;
    if (resolver != null) return resolver();
    throw PackFailure(
        'libraryRootResolver not configured — register library bindings first');
  }

  Future<File> _packFile(String packId) async {
    final root = await _root();
    final dir = Directory(
        '${root.path}${Platform.pathSeparator}$libraryFolderName');
    // Sync create: the read path must stay FakeAsync-safe for widget tests
    // (a real async mkdir never completes under the test zone) and is a
    // no-op when the folder already exists.
    dir.createSync(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}$packId.json');
  }

  /// Installs a pack: download -> validate -> promote -> registry row.
  ///
  /// Throws [PackFailure] (or the underlying Dio error) on any failure; on
  /// failure the dot-part is deleted, the final file is untouched and NO
  /// registry row is written.
  Future<File> install(
    LibraryPackInfo pack, {
    void Function(int received, int total)? onProgress,
  }) async {
    final finalFile = await _packFile(pack.id);
    final partFile = File('${finalFile.path}.part');
    final expectedBytes = (pack.approxSizeMb * 1024 * 1024).round();
    try {
      final sink = partFile.openWrite();
      var received = 0;
      try {
        switch (pack.kind) {
          case LibraryPackKind.tafsir:
            if (pack.urlTemplate == null || pack.fileCount == null) {
              throw PackFailure('tafsir pack missing urlTemplate/fileCount');
            }
            sink.write(_wrapperPrefix(pack.id));
            var separator = '';
            for (var n = 1; n <= pack.fileCount!; n++) {
              final url = pack.urlTemplate!.replaceFirst('{n}', '$n');
              final dr = await _dio.get<String>(url);
              final body = dr.data ?? '';
              final perSurah = jsonDecode(body);
              if (perSurah is! List || perSurah.isEmpty) {
                throw PackFailure('tafsir surah $n is empty or not an array');
              }
              received += utf8.encode(body).length;
              if (received > _sizeCap(expectedBytes)) {
                throw PackFailure(
                    'pack "${pack.id}" exceeds its declared size');
              }
              // Flatten: splice the per-surah array interior verbatim so the
              // wrapper's tafsirs list stays a flat (surah, ayah, text) list.
              final trimmed = body.trim();
              if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
                throw PackFailure('tafsir surah $n is not a JSON array');
              }
              final interior = trimmed.substring(1, trimmed.length - 1).trim();
              if (interior.isEmpty) {
                throw PackFailure('tafsir surah $n is empty');
              }
              sink.write('$separator$interior');
              separator = ',';
              onProgress?.call(received, expectedBytes);
            }
            sink.write(']}');
          case LibraryPackKind.translation:
          case LibraryPackKind.hadith:
            if (pack.sourceUrl == null) {
              throw PackFailure('single-file pack missing sourceUrl');
            }
            final res = await _dio.get<ResponseBody>(
              pack.sourceUrl!,
              options: Options(responseType: ResponseType.stream),
            );
            final contentLength =
                int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? '') ?? 0;
            final total = contentLength > 0 ? contentLength : expectedBytes;
            await for (final chunk in res.data!.stream) {
              received += chunk.length;
              if (received > _sizeCap(expectedBytes)) {
                throw PackFailure(
                    'pack "${pack.id}" exceeds its declared size');
              }
              sink.add(chunk);
              onProgress?.call(received, total);
            }
        }
        await sink.flush();
      } on Object {
        await sink.close();
        rethrow;
      }
      await sink.close();

      final decoded = await _sniffIntegrity(pack.id, pack.kind, partFile);

      final promoted = await partFile.rename(partFile.path
          .substring(0, partFile.path.length - '.part'.length));
      final sizeMb = await promoted.length() / (1024 * 1024);
      await _upsertRow(
        packId: pack.id,
        kind: pack.kind.name,
        language: pack.language,
        title: pack.titleAr,
        version: pack.version,
        sizeMb: sizeMb,
      );
      _decodedCache[pack.id] = decoded;
      return promoted;
    } on Object {
      _decodedCache.remove(pack.id);
      if (await partFile.exists()) {
        await partFile.delete();
      }
      rethrow;
    }
  }

  /// Validates the downloaded shape and returns the decoded JSON so the
  /// caller can prime the read cache instead of decoding the file again.
  Future<dynamic> _sniffIntegrity(
      String packId, LibraryPackKind kind, File part) async {
    final raw = await part.readAsString();
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on Object {
      throw PackFailure('downloaded pack "$packId" did not parse as JSON');
    }
    switch (kind) {
      case LibraryPackKind.translation:
        final list = (decoded as Map<String, dynamic>)['quran'];
        if (list is! List || list.isEmpty) {
          throw PackFailure('pack "$packId" missing a non-empty quran list');
        }
      case LibraryPackKind.hadith:
        final list = (decoded as Map<String, dynamic>)['hadiths'];
        if (list is! List || list.isEmpty) {
          throw PackFailure('pack "$packId" missing a non-empty hadiths list');
        }
      case LibraryPackKind.tafsir:
        final map = decoded as Map<String, dynamic>;
        if (map['pack'] != packId) {
          throw PackFailure('wrapper pack mismatch for "$packId"');
        }
        final list = map['tafsirs'];
        if (list is! List || list.isEmpty) {
          throw PackFailure('wrapper for "$packId" has no tafsirs');
        }
    }
    return decoded;
  }

  String _wrapperPrefix(String packId) =>
      '{"pack":"$packId","tafsirs":[';

  Future<void> _upsertRow({
    required String packId,
    required String kind,
    required String language,
    required String title,
    required String version,
    required double sizeMb,
  }) async {
    final existing = await (_db.select(_db.installedPacks)
          ..where((p) => p.packId.equals(packId)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.installedPacks).insert(InstalledPacksCompanion.insert(
            packId: packId,
            kind: kind,
            language: language,
            title: title,
            sizeMb: sizeMb,
            version: version,
          ));
    } else {
      await (_db.update(_db.installedPacks)
            ..where((p) => p.packId.equals(existing.packId)))
          .write(InstalledPacksCompanion(
        kind: Value(kind),
        language: Value(language),
        title: Value(title),
        version: Value(version),
        sizeMb: Value(sizeMb),
      ));
    }
  }

  Future<void> uninstall(String packId) async {
    final row = await (_db.select(_db.installedPacks)
          ..where((p) => p.packId.equals(packId)))
        .getSingleOrNull();
    final finalFile = await _packFile(packId);
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    if (row != null) {
      await (_db.delete(_db.installedPacks)
            ..where((p) => p.packId.equals(packId)))
          .go();
    }
    _decodedCache.remove(packId);
  }

  /// True when the pack is installed AND at exactly [version].
  Future<bool> isInstalled(String packId, String version) async {
    final row = await (_db.select(_db.installedPacks)
          ..where((p) => p.packId.equals(packId)))
        .getSingleOrNull();
    return row != null && row.version == version;
  }

  Future<bool> isInstalledAny(String packId) async {
    final row = await (_db.select(_db.installedPacks)
          ..where((p) => p.packId.equals(packId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<List<InstalledPack>> installedPacks() =>
      _db.select(_db.installedPacks).get();

  /// Path of an installed pack's file, null when absent.
  Future<String?> packPath(String packId) async {
    final row = await (_db.select(_db.installedPacks)
          ..where((p) => p.packId.equals(packId)))
        .getSingleOrNull();
    if (row == null) return null;
    final f = await _packFile(packId);
    return f.existsSync() ? f.path : null;
  }

  Future<dynamic> _decodeInstalled(String packId,
      {String? key, bool Function(List)? nonEmpty}) async {
    final path = await packPath(packId);
    if (path == null) {
      _decodedCache.remove(packId);
      return null;
    }
    var decoded = _decodedCache[packId];
    if (decoded == null) {
      try {
        decoded = jsonDecode(File(path).readAsStringSync());
      } on Object {
        return null; // corrupted pack reads as absent, never throws upward
      }
      _decodedCache[packId] = decoded;
    }
    if (key != null && decoded is Map<String, dynamic>) {
      final list = decoded[key];
      if (list is! List || (nonEmpty != null && !nonEmpty(list))) return null;
      return list;
    }
    return decoded;
  }

  /// Translation text for an ayah from an installed translation pack.
  Future<String?> translationFor(String packId, int surah, int ayah) async {
    final list = await _decodeInstalled(packId, key: 'quran');
    if (list is! List) return null;
    for (final entry in list) {
      if (entry is Map<String, dynamic> &&
          entry['chapter'] == surah &&
          entry['verse'] == ayah) {
        final text = entry['text'];
        if (text is String && text.isNotEmpty) return text;
      }
    }
    return null;
  }

  /// Tafsir text for an ayah from an installed tafsir wrapper.
  Future<String?> tafsirFor(String packId, int surah, int ayah) async {
    final list =
        await _decodeInstalled(packId, key: 'tafsirs');
    if (list is! List) return null;
    for (final entry in list) {
      if (entry is Map<String, dynamic> &&
          entry['surah'] == surah &&
          entry['ayah'] == ayah) {
        final text = entry['text'];
        if (text is String && text.isNotEmpty) return text;
      }
    }
    return null;
  }

  /// A paged window of an installed hadith pack:
  /// `([ (hadithnumber, text), ... ], hasMore)`.
  Future<(List<(int, String)>, bool)> hadithPage(
      String packId, int offset, int limit) async {
    final list = await _decodeInstalled(packId, key: 'hadiths');
    if (list is! List || offset >= list.length || offset < 0 || limit <= 0) {
      return (const <(int, String)>[], false);
    }
    final end = (offset + limit).clamp(0, list.length);
    final out = <(int, String)>[];
    for (final entry in list.sublist(offset, end)) {
      if (entry is Map<String, dynamic>) {
        final number = (entry['hadithnumber'] as num?)?.toInt();
        final text = entry['text'];
        if (number != null && text is String) {
          out.add((number, text));
        }
      }
    }
    return (out, end < list.length);
  }
}
