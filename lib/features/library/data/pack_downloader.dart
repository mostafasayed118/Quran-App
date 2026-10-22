import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

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

/// The projection of one tafsir surah body: the ayah index and the array
/// interior the wrapper splices verbatim. [error] is the shape failure
/// (null when the body is valid).
typedef _SurahProjection = ({
  String? error,
  Map<int, String> index,
  String interior
});

/// Why the install sniff rejected a downloaded pack.
enum _SniffError { parse, notObject, quran, hadiths, packMismatch, noTafsirs }

/// The sniff verdict: the shape failure (null when the pack is valid) and the
/// projection the read path needs — the decoded tree itself never crosses an
/// isolate port.
typedef _SniffResult = ({_SniffError? error, Object? projection});

/// The shared byte counter of one pack download.
///
/// The size cap covers the WHOLE pack, so every in-flight stream of the
/// tafsir fetch window adds to this one counter.
class _ByteCounter {
  int value = 0;
}

/// How many tafsir surahs are fetched in parallel and decoded per worker
/// isolate. A small window: enough to hide the per-request latency, small
/// enough to bound the memory and the load on the origin.
const int _tafsirBatchSize = 4;

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
/// - tafsir: GET loop over [LibraryPackInfo.urlTemplate]
///   (n = 1..fileCount, plain `n.json`) with a BOUNDED concurrency window,
///   streaming the REAL per-surah
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
  /// synchronous decoder. The sniff projects inside a worker isolate when no
  /// decoder is injected.
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
    try {
      // Tafsir only: the ayah index merged from the per-surah bodies during
      // the install loop, so the wrapper never has to be decoded again just to
      // prime the read cache.
      final mergedIndex = await _writePack(pack, partFile, onProgress);
      // A tafsir pack pinned per surah needs no end-of-install wrapper
      // decode: every served byte was hash-verified and the wrapper itself is
      // written here. Unpinned tafsirs keep the full-wrapper sniff as the
      // validation gate.
      final pinnedTafsir =
          pack.kind == LibraryPackKind.tafsir && pack.sha256PerSurah != null;
      if (!pinnedTafsir) {
        // An unpinned pack is validated by SHAPE only - the degradation must
        // never be silent. The bundled catalog is fully pinned (the loader
        // gate), so this only fires for a pack that reached the downloader
        // without its integrity hashes.
        final gap = catalogIntegrityGap(pack);
        if (gap != null) {
          dev.log(
              'pack "${pack.id}" is not integrity-pinned ($gap): the install is validated by shape only',
              name: 'quran_yahdi/library');
        }
      }
      final projection = pinnedTafsir ? null : await _sniffPack(pack, partFile);
      final promoted = await _store.promote(partFile);
      await _registerRow(pack, promoted);
      _primeReadCache(pack, mergedIndex, projection);
      return promoted;
    } on Object {
      _reader.invalidate(pack.id);
      await _store.deleteIfExists(partFile);
      rethrow;
    }
  }

  /// Streams the pack into its dot-part file.
  ///
  /// Returns the merged ayah index (tafsir only); the other kinds return
  /// null because their index is built by the install sniff.
  Future<Map<int, String>?> _writePack(
    LibraryPackInfo pack,
    File partFile,
    void Function(int received, int total)? onProgress,
  ) async {
    final expectedBytes = (pack.approxSizeMb * 1024 * 1024).round();
    final throttle = ProgressThrottle();
    final sink = partFile.openWrite();
    Map<int, String>? mergedIndex;
    try {
      switch (pack.kind) {
        case LibraryPackKind.tafsir:
          mergedIndex = await _writeTafsir(
              pack, sink, expectedBytes, throttle, onProgress);
        case LibraryPackKind.translation:
        case LibraryPackKind.hadith:
          await _writeSingleFile(
              pack, sink, expectedBytes, throttle, onProgress);
      }
      await sink.flush();
    } on Object {
      await sink.close();
      rethrow;
    }
    await sink.close();
    return mergedIndex;
  }

  /// The tafsir install loop: one GET per surah, hash-verified BEFORE its
  /// body is decoded, spliced verbatim into the documented wrapper.
  ///
  /// The surahs are fetched with BOUNDED concurrency (a window of
  /// [_tafsirBatchSize] requests in flight) and decoded in batches - one
  /// worker isolate per batch, not one per surah. The wrapper is still
  /// written in surah order, and every body is hash-verified before it is
  /// decoded or spliced, so the sha256 gate stays exactly as strict.
  Future<Map<int, String>> _writeTafsir(
    LibraryPackInfo pack,
    IOSink sink,
    int expectedBytes,
    ProgressThrottle throttle,
    void Function(int received, int total)? onProgress,
  ) async {
    final urlTemplate = pack.urlTemplate;
    final fileCount = pack.fileCount;
    if (urlTemplate == null || fileCount == null) {
      throw PackFailure('tafsir pack missing urlTemplate/fileCount');
    }
    final perSurahHashes = pack.sha256PerSurah;
    if (perSurahHashes != null && perSurahHashes.length != fileCount) {
      throw PackFailure('tafsir pack "${pack.id}" hash count mismatch');
    }
    final merged = <int, String>{};
    final received = _ByteCounter();
    var separator = '';
    sink.write(_wrapperPrefix(pack.id));
    for (var start = 1; start <= fileCount; start += _tafsirBatchSize) {
      final last = start + _tafsirBatchSize - 1;
      final end = last < fileCount ? last : fileCount;
      final numbers = <int>[for (var n = start; n <= end; n++) n];
      // (a) fetch the window with bounded concurrency.
      final bodies = await Future.wait([
        for (final n in numbers)
          _downloadSurah(
            urlTemplate.replaceFirst('{n}', '$n'),
            pack,
            expectedBytes,
            received,
          ),
      ]);
      // (b) verify EVERY hash of the window before any body is decoded.
      for (var i = 0; i < numbers.length; i++) {
        final n = numbers[i];
        if (perSurahHashes != null &&
            sha256.convert(bodies[i]).toString() != perSurahHashes[n - 1]) {
          throw PackFailure('tafsir surah $n failed sha256 verification');
        }
      }
      // (c) decode the whole window in ONE worker isolate.
      final projections = await _decodeSurahs(bodies);
      // (d) splice the window in surah order.
      for (var i = 0; i < numbers.length; i++) {
        final projection = projections[i];
        final error = projection.error;
        if (error != null) {
          throw PackFailure('tafsir surah ${numbers[i]} is $error');
        }
        // Keys are global (`surah * 1000 + ayah`), so merging the per-surah
        // indexes is exact and cannot collide.
        merged.addAll(projection.index);
        // Flatten: splice the per-surah array interior verbatim so the
        // wrapper's tafsirs list stays a flat (surah, ayah, text) list.
        sink.write('$separator${projection.interior}');
        separator = ',';
      }
      if (throttle.shouldReport(received.value, expectedBytes)) {
        onProgress?.call(received.value, expectedBytes);
      }
    }
    sink.write(']}');
    return merged;
  }

  /// Streams one surah body, enforcing the pack-wide size cap.
  ///
  /// The cap counts every byte received for the whole pack, so the received
  /// total is carried across the surahs - and across the concurrent window:
  /// every in-flight stream adds to the same counter.
  ///
  /// The body is accumulated in a [BytesBuilder]: one contiguous buffer
  /// instead of a per-byte [List] (8 bytes per element), and the buffer
  /// crosses the isolate port zero-copy.
  Future<Uint8List> _downloadSurah(
    String url,
    LibraryPackInfo pack,
    int expectedBytes,
    _ByteCounter received,
  ) async {
    // Streamed, not buffered: a compromised/mutable upstream must not be able
    // to force a full multi-MB body into memory before the size guard fires.
    // The cap is checked per chunk.
    final res = await _dio.get<ResponseBody>(
      url,
      options: Options(responseType: ResponseType.stream),
    );
    final body = res.data;
    if (body == null) throw PackFailure('empty response body');
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in body.stream) {
      received.value += chunk.length;
      if (received.value > _sizeCap(expectedBytes)) {
        throw PackFailure('pack "${pack.id}" exceeds its declared size');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  /// The single-file install path (translation/hadith): the body streams into
  /// the dot-part while it is hashed, and the sha256 gate runs before the
  /// file is ever promoted.
  Future<void> _writeSingleFile(
    LibraryPackInfo pack,
    IOSink sink,
    int expectedBytes,
    ProgressThrottle throttle,
    void Function(int received, int total)? onProgress,
  ) async {
    final sourceUrl = pack.sourceUrl;
    if (sourceUrl == null) {
      throw PackFailure('single-file pack missing sourceUrl');
    }
    final res = await _dio.get<ResponseBody>(
      sourceUrl,
      options: Options(responseType: ResponseType.stream),
    );
    final contentLength =
        int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? '') ?? 0;
    final total = contentLength > 0 ? contentLength : expectedBytes;
    final expectedSha = pack.sha256;
    // O(1) hashing: feed every chunk straight into the sha256 sink
    // instead of accumulating the whole body in a second buffer.
    final digestSink = expectedSha == null ? null : _DigestSink();
    final hasher =
        digestSink == null ? null : sha256.startChunkedConversion(digestSink);
    var received = 0;
    final body = res.data;
    if (body == null) throw PackFailure('empty response body');
    await for (final chunk in body.stream) {
      received += chunk.length;
      if (received > _sizeCap(expectedBytes)) {
        throw PackFailure('pack "${pack.id}" exceeds its declared size');
      }
      sink.add(chunk);
      hasher?.add(chunk);
      if (throttle.shouldReport(received, total)) {
        onProgress?.call(received, total);
      }
    }
    _verifyPinnedHash(pack, expectedSha, digestSink, hasher);
  }

  /// Verifies the streamed body against the pinned sha256.
  ///
  /// The digest is closed here — after the whole body was hashed and before
  /// the file can ever be promoted.
  static void _verifyPinnedHash(
    LibraryPackInfo pack,
    String? expectedSha,
    _DigestSink? digestSink,
    ByteConversionSink? hasher,
  ) {
    if (expectedSha == null) return;
    if (hasher == null || digestSink == null) {
      throw PackFailure('pack "${pack.id}" hash sink missing');
    }
    hasher.close();
    if (digestSink.value.toString() != expectedSha) {
      throw PackFailure('pack "${pack.id}" failed sha256 verification');
    }
  }

  /// Decodes a batch of tafsir surah bodies in ONE worker isolate and returns
  /// ONLY what the install needs: the ayah index and the array interior the
  /// wrapper splices verbatim. The JSON parse never runs on the UI isolate.
  ///
  /// The bodies are [Uint8List]s, so they cross the isolate port zero-copy.
  static Future<List<_SurahProjection>> _decodeSurahs(List<Uint8List> bodies) =>
      Isolate.run(() => [for (final bytes in bodies) _projectSurah(bytes)]);

  /// The worker-side projection of one surah body.
  ///
  /// [error] is the shape failure (null when the body is valid); a body that
  /// is not JSON at all throws inside the worker and the failure reaches the
  /// caller unchanged.
  static _SurahProjection _projectSurah(List<int> bytes) {
    final body = utf8.decode(bytes);
    final perSurah = jsonDecode(body);
    if (perSurah is! List || perSurah.isEmpty) {
      return const (
        error: 'empty or not an array',
        index: <int, String>{},
        interior: '',
      );
    }
    final trimmed = body.trim();
    if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
      return const (
        error: 'not a JSON array',
        index: <int, String>{},
        interior: '',
      );
    }
    final interior = trimmed.substring(1, trimmed.length - 1).trim();
    if (interior.isEmpty) {
      return const (
        error: 'empty',
        index: <int, String>{},
        interior: '',
      );
    }
    return (
      error: null,
      index: PackReader.buildAyahIndex(perSurah),
      interior: interior,
    );
  }

  /// Validates the downloaded shape and returns the projection the read path
  /// needs (an ayah index, or the raw hadith list) so the caller can prime
  /// the read cache instead of decoding the file again.
  ///
  /// The decoded tree never crosses an isolate port: the production path
  /// decodes, validates and projects inside ONE worker isolate.
  Future<Object?> _sniffPack(LibraryPackInfo pack, File part) async {
    final decoder = _fileDecoder;
    final _SniffResult result;
    if (decoder == null) {
      result = await _sniffInIsolate(part.path, pack);
    } else {
      dynamic decoded;
      try {
        decoded = await decoder(part.path);
      } on Object {
        throw PackFailure('downloaded pack "${pack.id}" did not parse as JSON');
      }
      result = _sniffTree(decoded, pack);
    }
    final error = result.error;
    if (error != null) {
      throw PackFailure(_sniffFailureMessage(error, pack.id));
    }
    return result.projection;
  }

  /// The production sniff: the decode, the shape check and the projection all
  /// happen inside one worker isolate — only the verdict and the projection
  /// cross the port.
  static Future<_SniffResult> _sniffInIsolate(
          String path, LibraryPackInfo pack) =>
      Isolate.run(() {
        dynamic decoded;
        try {
          decoded = jsonDecode(File(path).readAsStringSync());
        } on Object {
          return const (error: _SniffError.parse, projection: null);
        }
        return _sniffTree(decoded, pack);
      });

  /// The shape check and the projection of an already-decoded pack tree.
  static _SniffResult _sniffTree(dynamic decoded, LibraryPackInfo pack) {
    final map = decoded;
    if (map is! Map<String, dynamic>) {
      return const (error: _SniffError.notObject, projection: null);
    }
    switch (pack.kind) {
      case LibraryPackKind.translation:
        final list = map['quran'];
        if (list is! List || list.isEmpty) {
          return const (error: _SniffError.quran, projection: null);
        }
        return (error: null, projection: PackReader.buildAyahIndex(list));
      case LibraryPackKind.hadith:
        final list = map['hadiths'];
        if (list is! List || list.isEmpty) {
          return const (error: _SniffError.hadiths, projection: null);
        }
        return (error: null, projection: list);
      case LibraryPackKind.tafsir:
        if (map['pack'] != pack.id) {
          return const (error: _SniffError.packMismatch, projection: null);
        }
        final list = map['tafsirs'];
        if (list is! List || list.isEmpty) {
          return const (error: _SniffError.noTafsirs, projection: null);
        }
        return (error: null, projection: PackReader.buildAyahIndex(list));
    }
  }

  /// The failure message of a sniff verdict (verbatim, per pack kind).
  static String _sniffFailureMessage(_SniffError error, String packId) =>
      switch (error) {
        _SniffError.parse => 'downloaded pack "$packId" did not parse as JSON',
        _SniffError.notObject =>
          'downloaded pack "$packId" is not a JSON object',
        _SniffError.quran => 'pack "$packId" missing a non-empty quran list',
        _SniffError.hadiths =>
          'pack "$packId" missing a non-empty hadiths list',
        _SniffError.packMismatch => 'wrapper pack mismatch for "$packId"',
        _SniffError.noTafsirs => 'wrapper for "$packId" has no tafsirs',
      };

  /// Primes the read cache from the install-time projections: the merged
  /// per-surah index (tafsir) or the sniffed projection (translation/hadith).
  void _primeReadCache(
    LibraryPackInfo pack,
    Map<int, String>? mergedIndex,
    Object? projection,
  ) {
    switch (pack.kind) {
      case LibraryPackKind.tafsir:
        final merged = mergedIndex;
        if (merged != null) _reader.primeAyahIndex(pack.id, merged);
      case LibraryPackKind.translation:
        final index = projection;
        if (index is Map<int, String>) _reader.primeAyahIndex(pack.id, index);
      case LibraryPackKind.hadith:
        final list = projection;
        if (list is List) _reader.primeList(pack.id, list);
    }
  }

  String _wrapperPrefix(String packId) => '{"pack":"$packId","tafsirs":[';

  /// Writes (or refreshes) the installed-pack row of a promoted pack.
  Future<void> _registerRow(LibraryPackInfo pack, File promoted) async {
    final sizeMb = await promoted.length() / (1024 * 1024);
    final existing = await (_db.select(_db.installedPacks)
          ..where((p) => p.packId.equals(pack.id)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.installedPacks).insert(InstalledPacksCompanion.insert(
            packId: pack.id,
            kind: pack.kind.name,
            language: pack.language,
            title: pack.titleAr,
            sizeMb: sizeMb,
            version: pack.version,
          ));
    } else {
      await (_db.update(_db.installedPacks)
            ..where((p) => p.packId.equals(existing.packId)))
          .write(InstalledPacksCompanion(
        kind: Value(pack.kind.name),
        language: Value(pack.language),
        title: Value(pack.titleAr),
        version: Value(pack.version),
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

/// Collects the single digest produced by [sha256.startChunkedConversion].
///
/// The streaming install path feeds the digest sink chunk by chunk, so the
/// whole body is never retained a second time just to hash it.
class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
