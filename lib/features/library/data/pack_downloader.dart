import 'dart:async';
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
import 'hadith_store.dart';
import 'library_catalog.dart';
import 'pack_reader.dart';
import 'pack_redirect_guard.dart';
import 'pack_store.dart';

part 'pack_downloader_sniff.dart';
part 'pack_downloader_types.dart';

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

  /// DB-backed hadith read index: imports the install projection once, then
  /// serves pages with SQL LIMIT/OFFSET instead of retaining the pack list.
  late final HadithStore _hadithStore = HadithStore(
    _db,
    packPath: packPath,
    fileDecoder: _fileDecoder,
  );

  /// Filesystem side: safe pack-file resolution and the part-file lifecycle.
  late final PackStore _store = PackStore(
    rootResolver: _rootResolver,
    folderName: libraryFolderName,
  );

  static const libraryFolderName = 'library';

  /// Guard against a lying/compromised host streaming unbounded bytes:
  /// allow up to 2x the declared size plus 64 KiB slack.
  static int _sizeCap(int expectedBytes) => guardedByteCap(expectedBytes);

  /// In-flight installs keyed by pack id (single-flight gate).
  final Map<String, Future<File>> _installs = {};

  /// In-flight progress owned by the app-scoped downloader, not by whichever
  /// route cubit happened to start the install.
  final Map<String, (int, int)> _progress = {};
  final StreamController<Map<String, (int, int)>> _progressController =
      StreamController<Map<String, (int, int)>>.broadcast();

  /// A snapshot of the current in-flight progress, for a cubit that mounts
  /// while an install is already running.
  Map<String, (int, int)> get progress => Map.unmodifiable(_progress);

  /// Emits a snapshot whenever an install starts, reports bytes, or settles.
  Stream<Map<String, (int, int)>> get progressStream =>
      _progressController.stream;

  /// Installs a pack at most once at a time. Concurrent callers share the
  /// in-flight future; the second caller gets the same promoted file and does
  /// not open a second writer on the same `.part`.
  ///
  /// Progress is recorded on this app-scoped object and broadcast; the
  /// caller's optional callback is retained for the existing UI seam.
  ///
  /// Throws [PackFailure] (or the underlying Dio error) on any failure; on
  /// failure the dot-part is deleted, the final file is untouched and NO
  /// registry row is written.
  Future<File> install(
    LibraryPackInfo pack, {
    void Function(int received, int total)? onProgress,
  }) {
    final inFlight = _installs[pack.id];
    if (inFlight != null) return inFlight;
    final future = _installOnce(
      pack,
      onProgress: (received, total) {
        _progress[pack.id] = (received, total);
        _emitProgress();
        onProgress?.call(received, total);
      },
    );
    _installs[pack.id] = future;
    future.whenComplete(() {
      if (identical(_installs[pack.id], future)) {
        _installs.remove(pack.id);
      }
      if (_progress.remove(pack.id) != null) {
        _emitProgress();
      }
    }).ignore();
    return future;
  }

  void _emitProgress() {
    _progressController.add(Map.unmodifiable(_progress));
  }

  Future<File> _installOnce(
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
      try {
        await _registerRow(pack, promoted);
      } on Object {
        // The file was promoted before the registry row was written. Leaving
        // it behind would create an invisible multi-MB orphan that the next
        // install overwrites and `uninstall` can never reach.
        await _store.deleteIfExists(promoted);
        rethrow;
      }
      await _importHadith(pack, projection);
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
  /// written in surah order, and every body is hash-verified inside the
  /// worker before it is decoded or spliced, so the sha256 gate stays exactly
  /// as strict.
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
      // (b) decode the whole window in ONE worker isolate; every body is
      // hash-verified there, before it is decoded.
      final projections = await _decodeSurahs(bodies, numbers, [
        for (final n in numbers)
          perSurahHashes == null ? null : perSurahHashes[n - 1],
      ]);
      // (c) splice the window in surah order.
      for (var i = 0; i < numbers.length; i++) {
        final projection = projections[i];
        final error = projection.error;
        if (error == _shaMismatchError) {
          throw PackFailure(
              'tafsir surah ${numbers[i]} failed sha256 verification');
        }
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

  /// Fetches [start] while following at most [kMaxPackRedirectHops] redirects
  /// manually. Every hop must stay on HTTPS and [kTrustedPackHosts]; Dio is not
  /// allowed to follow a redirect it cannot re-validate.
  Future<Response<ResponseBody>> _fetchTrustedPack(Uri start) async {
    var current = start;
    for (var hop = 0; hop <= kMaxPackRedirectHops; hop++) {
      final res = await _dio.get<ResponseBody>(
        current.toString(),
        options: Options(
          responseType: ResponseType.stream,
          // Dio must hand every 3xx back instead of following it itself.
          followRedirects: false,
          validateStatus: _acceptSuccessOrRedirect,
        ),
      );
      final status = res.statusCode ?? 0;
      if (!_redirectStatuses.contains(status)) return res;
      final location = res.headers.value('location')?.trim();
      await _discardRedirectBody(res.data);
      if (location == null || location.isEmpty) {
        throw PackFailure('pack redirect $status is missing a Location header');
      }
      try {
        current = resolveTrustedPackRedirect(current, location);
      } on PackRedirectException catch (error) {
        throw PackFailure(error.message);
      }
    }
    throw PackFailure(
        'pack redirect chain exceeded $kMaxPackRedirectHops hops');
  }

  /// 2xx streams as before; 3xx must reach the hop guard rather than being
  /// collapsed into a [DioException] before its Location can be inspected.
  static bool _acceptSuccessOrRedirect(int? status) =>
      status != null &&
      ((status >= 200 && status < 300) || _redirectStatuses.contains(status));

  /// Releases a redirect response body so its socket is not left half-read.
  static Future<void> _discardRedirectBody(ResponseBody? body) async {
    if (body == null) return;
    try {
      await body.stream.drain<void>();
    } on Object catch (_) {
      // A broken redirect body cannot change the guard's verdict.
    }
  }

  static const Set<int> _redirectStatuses = {301, 302, 303, 307, 308};

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
    final res = await _fetchTrustedPack(Uri.parse(url));
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
    final res = await _fetchTrustedPack(Uri.parse(sourceUrl));
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

  /// Primes the read cache from the install-time projections: the merged
  /// per-surah index (tafsir) or the sniffed translation index.
  ///
  /// Hadith packs are deliberately NOT cached here: the DB import owns their
  /// read path, and retaining the full list would defeat the paging win.
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
        break;
    }
  }

  /// Imports the install-time hadith projection into the DB index.
  ///
  /// Best-effort: a DB failure must not fail an otherwise valid install; the
  /// first browse retries the import lazily from the pack file.
  Future<void> _importHadith(LibraryPackInfo pack, Object? projection) async {
    if (pack.kind != LibraryPackKind.hadith) return;
    try {
      await _hadithStore.importProjection(pack.id, projection);
    } on Object catch (error, stackTrace) {
      dev.log('hadith pack import failed',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
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
    // Row/index first, file last: a failed DB delete must leave a usable
    // installed pack, never a row whose file is already gone.
    if (row != null) {
      await (_db.delete(_db.installedPacks)
            ..where((p) => p.packId.equals(packId)))
          .go();
    }
    try {
      await _hadithStore.deletePack(packId);
    } on Object catch (error, stackTrace) {
      dev.log('hadith pack index cleanup failed',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
    }
    final finalFile = await _store.packFile(packId);
    await _store.deleteIfExists(finalFile);
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

  /// Drops the decoded pack cache; the next read re-decodes from disk.
  void trimReadCache() => _reader.trim();

  /// A paged window of an installed hadith pack:
  /// `([ (hadithnumber, text), ... ], hasMore)`.
  ///
  /// DB-backed in production. The in-memory reader stays as a fail-open
  /// fallback if the derived index cannot be built.
  Future<(List<(int, String)>, bool)> hadithPage(
      String packId, int offset, int limit) async {
    try {
      return await _hadithStore.hadithPage(packId, offset, limit);
    } on Object catch (error, stackTrace) {
      dev.log('hadith DB page failed; reading the pack directly',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
      return _reader.hadithPage(packId, offset, limit);
    }
  }
}
