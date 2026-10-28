import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/app_database.dart';
import '../../../core/utils/download_limits.dart';
import '../../../core/utils/progress_throttle.dart';
import 'download_status.dart';
import 'reciter_repository.dart';

/// Download transport budgets: a slow server must not hang a queued surah.
const Duration _connectTimeout = Duration(seconds: 15);
const Duration _receiveTimeout = Duration(minutes: 2);

/// Raised when a surah audio download cannot be completed.
class DownloadFailure implements Exception {
  DownloadFailure(this.message);

  /// Human-readable reason of the failure.
  final String message;
  @override
  String toString() => 'DownloadFailure: $message';
}

/// Downloads surah audio files and tracks them in the database.
class AudioDownloader {
  AudioDownloader(
    this._db, {
    Dio? dio,
    Future<Directory> Function()? audioRootResolver,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _connectTimeout,
              receiveTimeout: _receiveTimeout,
            )),
        _audioRoot = audioRootResolver;

  final AppDatabase _db;
  final Dio _dio;
  final Future<Directory> Function()? _audioRoot;

  /// Folder name under the app documents directory: 'audio'.
  static const audioFolderName = 'audio';

  /// Guard against a lying/compromised host streaming unbounded bytes:
  /// up to 2x the sent content-length plus 64 KiB slack, never above the
  /// [maxAcceptedBytesCeiling] absolute ceiling (a surah mp3 is ~1-2 MB) —
  /// a host that lies *large* about its content-length must not raise the
  /// accepted size along with it.
  static const int maxAcceptedBytesCeiling = 64 << 20;

  @visibleForTesting

  /// Byte cap accepted for a download, derived from the declared size.
  static int maxAcceptedBytes(int declaredTotal) =>
      guardedByteCap(declaredTotal, ceiling: maxAcceptedBytesCeiling);

  Future<Directory> _root() async {
    final resolver = _audioRoot;
    if (resolver != null) return resolver();
    throw DownloadFailure(
        'audioRootResolver not configured — call ensureAudioBindings() first');
  }

  Future<File> _targetFile(String rowId, int surahNumber) async {
    final rootDir = await _root();
    final folder = Directory(
        '${rootDir.path}${Platform.pathSeparator}$audioFolderName${Platform.pathSeparator}$rowId');
    await folder.create(recursive: true);
    return File(
        '${folder.path}${Platform.pathSeparator}${surahAudioFileName(surahNumber)}');
  }

  Future<void> _markStatus(String rowId, int surahNumber, DownloadStatus status,
      int bytes, String path) async {
    final existing = await (_db.select(_db.downloads)
          ..where(
              (d) => d.reciterId.equals(rowId) & d.surahId.equals(surahNumber)))
        .getSingleOrNull();
    if (existing == null) {
      // Read-then-write made conflict-safe: the (reciter, surah) pair is
      // unique, so a racing first-write must reuse the surviving row instead
      // of inserting a duplicate or throwing a constraint error.
      await _db.into(_db.downloads).insert(
            DownloadsCompanion.insert(
              reciterId: rowId,
              surahId: surahNumber,
              status: status.name,
              path: path,
              bytes: Value(bytes),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    // Runs for both branches: drift's insertOrIgnore reports the surviving
    // rowid (not an affected-row count), so this pair-scoped write is what
    // converges the racing caller onto the row that exists.
    await (_db.update(_db.downloads)
          ..where(
              (d) => d.reciterId.equals(rowId) & d.surahId.equals(surahNumber)))
        .write(DownloadsCompanion(
      status: Value(status.name),
      bytes: Value(bytes),
      path: Value(path),
    ));
  }

  /// Downloads one surah for [reciter]; reports progress and honours [cancelToken].
  Future<File> downloadSurah({
    required ReciterRow reciter,
    required int surahNumber,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final target = await _targetFile(reciter.id, surahNumber);
    final part = File('${target.path}.part');
    final url = surahAudioUrl(reciter.server, surahNumber);
    await _markStatus(
        reciter.id, surahNumber, DownloadStatus.downloading, 0, target.path);
    try {
      final res = await _dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );
      final total =
          int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? '') ??
              0;
      var received = 0;
      final throttle = ProgressThrottle();
      final body = res.data;
      if (body == null) throw DownloadFailure('empty audio response');
      final sink = part.openWrite();
      try {
        await for (final chunk in body.stream) {
          received += chunk.length;
          if (received > maxAcceptedBytes(total)) {
            throw DownloadFailure('audio stream exceeded its declared size');
          }
          sink.add(chunk);
          if (throttle.shouldReport(received, total)) {
            onProgress?.call(received, total);
          }
        }
        if (total > 0 && received != total) {
          throw DownloadFailure('audio body ended before its declared size');
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      final promoted = await _promotePart(part, target);
      final size = await promoted.length();
      await _markStatus(
          reciter.id, surahNumber, DownloadStatus.done, size, promoted.path);
      return promoted;
    } on Object {
      await _markStatus(
          reciter.id, surahNumber, DownloadStatus.failed, 0, target.path);
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  /// Moves [part] onto [target] without discarding the previous target until
  /// the new file is in place. A rename that cannot replace an existing
  /// target (Windows) parks the old file at `<target>.bak` and restores it if
  /// the swap fails.
  Future<File> _promotePart(File part, File target) async {
    final backup = File('${target.path}.bak');
    File? promoted;
    try {
      promoted = await part.rename(target.path);
    } on FileSystemException {
      if (!await target.exists()) rethrow;
    }
    if (promoted != null) {
      if (await backup.exists()) await backup.delete();
      return promoted;
    }
    if (await backup.exists()) await backup.delete();
    await target.rename(backup.path);
    File? swapped;
    try {
      swapped = await part.rename(target.path);
    } on Object {
      try {
        if (!await target.exists() && await backup.exists()) {
          await backup.rename(target.path);
        }
      } on Object catch (_) {}
      rethrow;
    }
    if (await backup.exists()) await backup.delete();
    return swapped;
  }

  /// True when the surah finished downloading for that reciter.
  Future<bool> isDownloaded(String rowId, int surahNumber) async {
    final row = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) &
              d.surahId.equals(surahNumber) &
              d.status.equals(DownloadStatus.done.name)))
        .getSingleOrNull();
    if (row == null) return false;
    return File(row.path).exists();
  }

  /// Path of the downloaded file, or null when it is not downloaded.
  Future<String?> downloadedPath(String rowId, int surahNumber) async {
    final row = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) &
              d.surahId.equals(surahNumber) &
              d.status.equals(DownloadStatus.done.name)))
        .getSingleOrNull();
    if (row == null) return null;
    return await File(row.path).exists() ? row.path : null;
  }

  /// Deletes the downloaded file and forgets the download row.
  Future<void> removeDownload(String rowId, int surahNumber) async {
    final row = await (_db.select(_db.downloads)
          ..where(
              (d) => d.reciterId.equals(rowId) & d.surahId.equals(surahNumber)))
        .getSingleOrNull();
    if (row != null) {
      await _deleteIfInsideAudioRoot(row.path);
      await (_db.delete(_db.downloads)..where((d) => d.id.equals(row.id))).go();
    }
  }

  /// Deletes [path] only when it lies under this downloader's audio root; a
  /// tampered registry row must never steer a delete outside app-owned files.
  /// The path is normalized first so separator style cannot bypass the check
  /// and `..` segments cannot climb out of the root.
  Future<void> _deleteIfInsideAudioRoot(String path) async {
    final rootDir = await _root();
    final audioRoot = p.join(rootDir.path, audioFolderName);
    final normalized = p.normalize(path);
    if (!p.isWithin(audioRoot, normalized)) return;
    final f = File(normalized);
    if (await f.exists()) await f.delete();
  }

  /// All completed-download rows (used by the queue cubit on startup).
  Future<List<Download>> listDone() => (_db.select(_db.downloads)
        ..where((d) => d.status.equals(DownloadStatus.done.name)))
      .get();
}
