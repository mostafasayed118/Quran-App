import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/download_limits.dart';
import '../../../core/utils/progress_throttle.dart';
import 'library_catalog.dart';
import 'pack_reader.dart';
import 'pack_store.dart';

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
    Future<dynamic> Function(String path)? fileDecoder,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(minutes: 2),
            )),
        _rootResolver = libraryRootResolver,
        _fileDecoder = fileDecoder;

  final AppDatabase _db;
  final Dio _dio;
  final Future<Directory> Function()? _rootResolver;

  /// The injectable decode seam (a TREE decoder), handed to the composed
  /// [PackReader] and used by the install integrity sniff. Null in production
  /// so the reader takes its isolate-projection read path; tests inject a
  /// synchronous decoder. The sniff falls back to
  /// [PackReader.decodeFileInIsolate].
  final Future<dynamic> Function(String path)? _fileDecoder;

  /// Read side: bounded decoded-pack cache, ayah indexes and the read API.
  late final PackReader _reader =
      PackReader(fileDecoder: _fileDecoder, packPath: packPath);

  /// Filesystem side: safe pack-file resolution and the part-file lifecycle.
  late final PackStore _store = PackStore(
    rootResolver: _rootResolver,
    folderName: libraryFolderName,
  );

  static const libraryFolderName = 'library';

  /// Guard against a lying/compromised host streaming unbounded bytes:
  /// allow up to 2x the declared size plus 64 KiB slack.
  static int _sizeCap(int expectedBytes) => guardedByteCap(expectedBytes);

  /// Installs a pack: download -> validate -> promote -> registry row.
  ///
  /// Throws [PackFailure] (or the underlying Dio error) on any failure; on
  /// failure the dot-part is deleted, the final file is untouched and NO
  /// registry row is written.
  Future<File> install(
    LibraryPackInfo pack, {
    void Function(int received, int total)? onProgress,
  }) async {
    final finalFile = await _store.packFile(pack.id);
    final partFile = _store.partFileFor(finalFile);
    final expectedBytes = (pack.approxSizeMb * 1024 * 1024).round();
    final throttle = ProgressThrottle();
    try {
      final sink = partFile.openWrite();
      var received = 0;
      try {
        switch (pack.kind) {
          case LibraryPackKind.tafsir:
            if (pack.urlTemplate == null || pack.fileCount == null) {
              throw PackFailure('tafsir pack missing urlTemplate/fileCount');
            }
            final perSurahHashes = pack.sha256PerSurah;
            if (perSurahHashes != null &&
                perSurahHashes.length != pack.fileCount) {
              throw PackFailure('tafsir pack "${pack.id}" hash count mismatch');
            }
            sink.write(_wrapperPrefix(pack.id));
            var separator = '';
            for (var n = 1; n <= pack.fileCount!; n++) {
              final url = pack.urlTemplate!.replaceFirst('{n}', '$n');
              // Streamed, not buffered: a compromised/mutable upstream must
              // not be able to force a full multi-MB body into memory before
              // the size guard fires. The cap is checked per chunk.
              final res = await _dio.get<ResponseBody>(
                url,
                options: Options(responseType: ResponseType.stream),
              );
              final bytes = <int>[];
              await for (final chunk in res.data!.stream) {
                received += chunk.length;
                if (received > _sizeCap(expectedBytes)) {
                  throw PackFailure(
                      'pack "${pack.id}" exceeds its declared size');
                }
                bytes.addAll(chunk);
              }
              if (perSurahHashes != null &&
                  sha256.convert(bytes).toString() != perSurahHashes[n - 1]) {
                throw PackFailure('tafsir surah $n failed sha256 verification');
              }
              final body = utf8.decode(bytes);
              final perSurah = jsonDecode(body);
              if (perSurah is! List || perSurah.isEmpty) {
                throw PackFailure('tafsir surah $n is empty or not an array');
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
              if (throttle.shouldReport(received, expectedBytes)) {
                onProgress?.call(received, expectedBytes);
              }
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
            final contentLength = int.tryParse(
                    res.headers.value(Headers.contentLengthHeader) ?? '') ??
                0;
            final total = contentLength > 0 ? contentLength : expectedBytes;
            final expectedSha = pack.sha256;
            final hashBytes = expectedSha == null ? null : <int>[];
            await for (final chunk in res.data!.stream) {
              received += chunk.length;
              if (received > _sizeCap(expectedBytes)) {
                throw PackFailure(
                    'pack "${pack.id}" exceeds its declared size');
              }
              sink.add(chunk);
              hashBytes?.addAll(chunk);
              if (throttle.shouldReport(received, total)) {
                onProgress?.call(received, total);
              }
            }
            if (expectedSha != null &&
                sha256.convert(hashBytes!).toString() != expectedSha) {
              throw PackFailure('pack "${pack.id}" failed sha256 verification');
            }
        }
        await sink.flush();
      } on Object {
        await sink.close();
        rethrow;
      }
      await sink.close();

      final decoded = await _sniffIntegrity(pack.id, pack.kind, partFile);

      final promoted = await _store.promote(partFile);
      final sizeMb = await promoted.length() / (1024 * 1024);
      await _upsertRow(
        packId: pack.id,
        kind: pack.kind.name,
        language: pack.language,
        title: pack.titleAr,
        version: pack.version,
        sizeMb: sizeMb,
      );
      _primeDecoded(pack.id, pack.kind, decoded);
      return promoted;
    } on Object {
      _reader.invalidate(pack.id);
      await _store.deleteIfExists(partFile);
      rethrow;
    }
  }

  /// Validates the downloaded shape and returns the decoded JSON so the
  /// caller can prime the read cache instead of decoding the file again.
  Future<dynamic> _sniffIntegrity(
      String packId, LibraryPackKind kind, File part) async {
    dynamic decoded;
    try {
      decoded =
          await (_fileDecoder ?? PackReader.decodeFileInIsolate)(part.path);
    } on Object {
      throw PackFailure('downloaded pack "$packId" did not parse as JSON');
    }
    final map = decoded;
    if (map is! Map<String, dynamic>) {
      throw PackFailure('downloaded pack "$packId" is not a JSON object');
    }
    switch (kind) {
      case LibraryPackKind.translation:
        final list = map['quran'];
        if (list is! List || list.isEmpty) {
          throw PackFailure('pack "$packId" missing a non-empty quran list');
        }
      case LibraryPackKind.hadith:
        final list = map['hadiths'];
        if (list is! List || list.isEmpty) {
          throw PackFailure('pack "$packId" missing a non-empty hadiths list');
        }
      case LibraryPackKind.tafsir:
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

  /// Primes the read cache from an install-time decode: an ayah index for
  /// translation/tafsir packs, the raw list for hadith packs.
  void _primeDecoded(String packId, LibraryPackKind kind, dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return;
    switch (kind) {
      case LibraryPackKind.translation:
        final list = decoded['quran'];
        if (list is List) {
          _reader.primeAyahIndex(packId, PackReader.buildAyahIndex(list));
        }
      case LibraryPackKind.hadith:
        final list = decoded['hadiths'];
        if (list is List) _reader.primeList(packId, list);
      case LibraryPackKind.tafsir:
        final list = decoded['tafsirs'];
        if (list is List) {
          _reader.primeAyahIndex(packId, PackReader.buildAyahIndex(list));
        }
    }
  }

  String _wrapperPrefix(String packId) => '{"pack":"$packId","tafsirs":[';

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
    final finalFile = await _store.packFile(packId);
    await _store.deleteIfExists(finalFile);
    if (row != null) {
      await (_db.delete(_db.installedPacks)
            ..where((p) => p.packId.equals(packId)))
          .go();
    }
    _reader.invalidate(packId);
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
    final f = await _store.packFile(packId);
    return f.existsSync() ? f.path : null;
  }

  /// Translation text for an ayah from an installed translation pack.
  Future<String?> translationFor(String packId, int surah, int ayah) =>
      _reader.translationFor(packId, surah, ayah);

  /// Tafsir text for an ayah from an installed tafsir wrapper.
  Future<String?> tafsirFor(String packId, int surah, int ayah) =>
      _reader.tafsirFor(packId, surah, ayah);

  /// A paged window of an installed hadith pack:
  /// `([ (hadithnumber, text), ... ], hasMore)`.
  Future<(List<(int, String)>, bool)> hadithPage(
          String packId, int offset, int limit) =>
      _reader.hadithPage(packId, offset, limit);
}
