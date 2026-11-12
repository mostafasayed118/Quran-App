import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/download_limits.dart';
import '../../../core/utils/progress_throttle.dart';
import '../../../core/utils/trusted_redirect.dart';
import 'hadith_store.dart';
import 'library_catalog.dart';
import 'pack_reader.dart';
import 'pack_redirect_guard.dart';
import 'pack_store.dart';

part 'pack_downloader_sniff.dart';
part 'pack_downloader_types.dart';
part 'pack_installer.dart';
part 'pack_integrity.dart';

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

  /// The install pipeline: stream, verify, promote and register one pack.
  late final _PackInstaller _installer = _PackInstaller(
    db: _db,
    dio: _dio,
    store: _store,
    reader: _reader,
    hadithStore: _hadithStore,
    fileDecoder: _fileDecoder,
  );

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
    final future = _installer.install(
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
      appLog('hadith pack index cleanup failed',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
    }
    final finalFile = await _store.packFile(packId);
    await _store.deleteIfExists(finalFile);
    _reader.invalidate(packId);
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

  /// The whole ayah index of an installed translation pack.
  Future<Map<int, String>> translationIndex(String packId) =>
      _reader.translationIndex(packId);

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
      appLog('hadith DB page failed; reading the pack directly',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
      return _reader.hadithPage(packId, offset, limit);
    }
  }

  /// A paged, diacritics-insensitive search over an installed hadith pack.
  Future<(List<(int, String)>, bool)> hadithSearch(
    String packId,
    String query, {
    int offset = 0,
    int limit = 20,
  }) =>
      _hadithStore.search(packId, query, offset: offset, limit: limit);

  /// The stored hadiths whose numbers are in [numbers], in book order.
  Future<List<(int, String)>> hadithByNumbers(
    String packId,
    Set<int> numbers,
  ) =>
      _hadithStore.byNumbers(packId, numbers);
}
