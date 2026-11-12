import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../core/db/app_database.dart';
import 'download_status.dart';

/// The `downloads` table and the files it points at, split out of
/// [AudioDownloader] so the transfer loop and the registry read as two jobs.
///
/// Every write here is pair-scoped on `(reciterId, surahId)`: the pair is
/// unique, so a racing first-write reuses the surviving row instead of
/// inserting a duplicate or throwing a constraint error.
class DownloadRegistry {
  DownloadRegistry(
    this._db, {
    required Future<Directory> Function() root,
    required String folderName,
  })  : _root = root,
        _folderName = folderName;

  final AppDatabase _db;
  final Future<Directory> Function() _root;

  /// Folder under the app documents directory that holds the audio files.
  final String _folderName;

  /// Upserts the row for one surah and its current transfer state.
  Future<void> mark(String rowId, int surahNumber, DownloadStatus status,
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

  /// Reconciles rows and dot-part files left by a killed process.
  ///
  /// A row that still says `downloading`/`queued` but has a complete target
  /// file is promoted to `done`; a row without a usable file becomes `failed`
  /// so it is retryable. A `.part` that belongs to a known, unfinished row is
  /// **kept** — it is resume material — and only orphan parts (no row at all)
  /// are removed. This must run before any new download starts.
  Future<void> reconcile() async {
    final root = await _root();
    final all = await _db.select(_db.downloads).get();
    // Parts owed by a row that is not done yet; a done row's staging file is
    // stale and gets swept.
    final keepParts = <String>{
      for (final row in all)
        if (row.path.isNotEmpty && row.status != DownloadStatus.done.name)
          p.normalize('${row.path}.part'),
    };
    final unfinished = all.where(
      (row) =>
          row.status == DownloadStatus.downloading.name ||
          row.status == DownloadStatus.queued.name,
    );
    for (final row in unfinished) {
      try {
        final target = row.path.isEmpty ? null : File(row.path);
        final part = row.path.isEmpty ? null : File('${row.path}.part');
        // Sync file checks keep this safe under the widget-test fake clock;
        // they are metadata-only and bounded to the audio root.
        if (target != null && target.existsSync() && target.lengthSync() > 0) {
          await mark(
            row.reciterId,
            row.surahId,
            DownloadStatus.done,
            target.lengthSync(),
            target.path,
          );
          if (part != null && part.existsSync()) part.deleteSync();
          keepParts.remove(p.normalize('${row.path}.part'));
        } else {
          await mark(
            row.reciterId,
            row.surahId,
            DownloadStatus.failed,
            0,
            row.path,
          );
          // The part stays: the next attempt resumes from it.
        }
      } on Object catch (error, stackTrace) {
        appLog('download reconcile row failed',
            name: 'quran_yahdi/downloads',
            error: error,
            stackTrace: stackTrace);
      }
    }
    final audioDir = Directory(
      '${root.path}${Platform.pathSeparator}$_folderName',
    );
    if (!audioDir.existsSync()) return;
    for (final entity
        in audioDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.part')) continue;
      if (keepParts.contains(p.normalize(entity.path))) continue;
      try {
        entity.deleteSync();
      } on Object catch (error, stackTrace) {
        appLog('download part cleanup failed',
            name: 'quran_yahdi/downloads',
            error: error,
            stackTrace: stackTrace);
      }
    }
  }

  /// The completed download row for [rowId]/[surahNumber], or null.
  Future<Download?> _doneRow(String rowId, int surahNumber) =>
      (_db.select(_db.downloads)
            ..where((d) =>
                d.reciterId.equals(rowId) &
                d.surahId.equals(surahNumber) &
                d.status.equals(DownloadStatus.done.name)))
          .getSingleOrNull();

  /// True when the surah finished downloading for that reciter.
  Future<bool> isDownloaded(String rowId, int surahNumber) async {
    final row = await _doneRow(rowId, surahNumber);
    if (row == null) return false;
    return File(row.path).exists();
  }

  /// Path of the downloaded file, or null when it is not downloaded.
  Future<String?> downloadedPath(String rowId, int surahNumber) async {
    final row = await _doneRow(rowId, surahNumber);
    if (row == null) return null;
    return await File(row.path).exists() ? row.path : null;
  }

  /// Deletes the downloaded file and forgets the download row.
  Future<void> forget(String rowId, int surahNumber) async {
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
    final audioRoot = p.join(rootDir.path, _folderName);
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
