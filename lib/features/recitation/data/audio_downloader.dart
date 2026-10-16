import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'reciter_repository.dart';

class DownloadFailure implements Exception {
  DownloadFailure(this.message);

  final String message;
  @override
  String toString() => 'DownloadFailure: $message';
}

class AudioDownloader {
  AudioDownloader(
    this._db, {
    Dio? dio,
    Future<Directory> Function()? audioRootResolver,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(minutes: 2),
            )),
        _audioRoot = audioRootResolver;

  final AppDatabase _db;
  final Dio _dio;
  final Future<Directory> Function()? _audioRoot;

  static const audioFolderName = 'audio';

  /// Guard against a lying/compromised host streaming unbounded bytes:
  /// up to 2x the sent content-length plus 64 KiB slack, or a 64 MiB hard
  /// ceiling when no content-length is sent (a surah mp3 is ~1-2 MB).
  static int _maxAcceptedBytes(int declaredTotal) =>
      declaredTotal > 0 ? declaredTotal * 2 + 65536 : 64 << 20;

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

  Future<void> _markStatus(
      String rowId, int surahNumber, String status, int bytes, String path) async {
    final existing = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) & d.surahId.equals(surahNumber)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.downloads).insert(DownloadsCompanion.insert(
            reciterId: rowId,
            surahId: surahNumber,
            status: status,
            path: path,
            bytes: Value(bytes),
          ));
    } else {
      await (_db.update(_db.downloads)
            ..where((d) => d.id.equals(existing.id)))
          .write(DownloadsCompanion(
        status: Value(status),
        bytes: Value(bytes),
        path: Value(path),
      ));
    }
  }

  Future<File> downloadSurah({
    required ReciterRow reciter,
    required int surahNumber,
    void Function(int received, int total)? onProgress,
  }) async {
    final target = await _targetFile(reciter.id, surahNumber);
    final url = surahAudioUrl(reciter.server, surahNumber);
    await _markStatus(reciter.id, surahNumber, 'downloading', 0, target.path);
    try {
      final res = await _dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
      );
      final total =
          int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? '') ?? 0;
      var received = 0;
      final sink = target.openWrite();
      try {
        await for (final chunk in res.data!.stream) {
          received += chunk.length;
          if (received > _maxAcceptedBytes(total)) {
            throw DownloadFailure('audio stream exceeded its declared size');
          }
          sink.add(chunk);
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      final size = await target.length();
      await _markStatus(reciter.id, surahNumber, 'done', size, target.path);
      return target;
    } on Object {
      await _markStatus(reciter.id, surahNumber, 'failed', 0, target.path);
      if (await target.exists()) {
        await target.delete();
      }
      rethrow;
    }
  }

  Future<bool> isDownloaded(String rowId, int surahNumber) async {
    final row = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) &
              d.surahId.equals(surahNumber) &
              d.status.equals('done')))
        .getSingleOrNull();
    if (row == null) return false;
    return File(row.path).exists();
  }

  Future<String?> downloadedPath(String rowId, int surahNumber) async {
    if (!await isDownloaded(rowId, surahNumber)) return null;
    final row = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) & d.surahId.equals(surahNumber)))
        .getSingleOrNull();
    return row?.path;
  }

  Future<void> removeDownload(String rowId, int surahNumber) async {
    final row = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) & d.surahId.equals(surahNumber)))
        .getSingleOrNull();
    if (row != null) {
      final f = File(row.path);
      if (await f.exists()) await f.delete();
      await (_db.delete(_db.downloads)..where((d) => d.id.equals(row.id))).go();
    }
  }

  /// All completed-download rows (used by the queue cubit on startup).
  Future<List<Download>> listDone() =>
      (_db.select(_db.downloads)..where((d) => d.status.equals('done'))).get();
}
