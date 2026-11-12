import 'dart:io';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/download_limits.dart';
import '../../../core/utils/progress_throttle.dart';
import '../../../core/utils/trusted_redirect.dart';
import 'download_registry.dart';
import 'download_status.dart';
import 'reciter_repository.dart';

part 'audio_download_types.dart';

/// Downloads surah audio files and tracks them in the database.
class AudioDownloader {
  AudioDownloader(
    this._db, {
    Dio? dio,
    Future<Directory> Function()? audioRootResolver,
    this.retryDelay = const Duration(seconds: 3),
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: _connectTimeout,
              receiveTimeout: _receiveTimeout,
            )),
        _audioRoot = audioRootResolver;

  final AppDatabase _db;
  final Dio _dio;
  final Future<Directory> Function()? _audioRoot;

  /// Pause before the single automatic retry of a failed transfer.
  ///
  /// Injected so tests can wait zero; null disables the retry entirely.
  final Duration? retryDelay;

  /// Hosts that answered a `Range` request with 200 (range unsupported).
  ///
  /// A cheap per-host capability probe: a host that ignored the header once is
  /// not asked again for this process's lifetime, so a resume attempt costs a
  /// whole-file download at most once per host.
  final Set<String> _hostsWithoutRange = <String>{};

  /// The `downloads` table and the files it points at.
  late final DownloadRegistry _registry = DownloadRegistry(
    _db,
    root: _root,
    folderName: audioFolderName,
  );

  /// Folder name under the app documents directory: 'audio'.
  static const audioFolderName = 'audio';

  /// Redirect hops honoured before the download is failed. Audio bytes carry
  /// no sha256 pin, so every hop is re-validated instead of letting the
  /// transport follow the CDN wherever it likes.
  static const int maxRedirectHops = 3;

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
    throw DownloadFailure.permanent(
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

  /// Fetches [start] while following at most [maxRedirectHops] redirects
  /// manually: a compromised CDN must not steer the download to `http://` or
  /// a foreign host. Returns the final (2xx) streaming response.
  Future<Response<ResponseBody>> _fetchTrustedRedirects(
    Uri start, {
    CancelToken? cancelToken,
    int rangeFrom = 0,
  }) async {
    return followTrustedRedirects(
      dio: _dio,
      start: start,
      maxHops: maxRedirectHops,
      devLogName: 'quran_yahdi/recitation',
      cancelToken: cancelToken,
      // Re-sent on every hop on purpose: a CDN redirect must not silently
      // turn a resume into a full download.
      headers: rangeFrom > 0
          ? <String, Object>{HttpHeaders.rangeHeader: 'bytes=$rangeFrom-'}
          : null,
      resolveNext: (current, location) {
        final next = current.resolve(location);
        if (next.scheme != 'http' && next.scheme != 'https') {
          throw DownloadFailure.permanent(
              'audio redirect to unsupported scheme "${next.scheme}"');
        }
        // Reuses the catalog allowlist (https + mp3quran.net) — one rule, one
        // place: a host that cannot be a reciter server cannot serve bytes.
        if (!isTrustedAudioServer(next.toString())) {
          throw DownloadFailure.permanent(
              'audio redirect to untrusted host ${next.host}');
        }
        return next;
      },
      failure: (message) => DownloadFailure.permanent('audio $message'),
    );
  }

  /// Reconciles rows and dot-part files left by a killed process.
  ///
  /// A row that still says `downloading`/`queued` but has a complete target
  /// file is promoted to `done`; a row without a usable file becomes `failed`
  /// so it is retryable. A `.part` that belongs to a known, unfinished row is
  /// **kept** — it is resume material — and only orphan parts (no row at all)
  /// are removed. This must run before any new download starts.
  Future<void> reconcileOnStart() => _registry.reconcile();

  /// Whether a failed attempt is worth one immediate retry.
  ///
  /// Network errors, timeouts, truncated bodies and the range mismatch (the
  /// prefix was already discarded) are transient. A body that exceeds its
  /// declared size is a lying host and is marked permanent, like a 4xx other
  /// than 408/416/429 (404 on a missing surah, 403 on a blocked host): retrying
  /// those would only burn the queue.
  static bool _isRetryable(Object error) {
    if (error is DownloadFailure) return error.retryable;
    if (error is DioException) {
      final status = error.response?.statusCode ?? 0;
      if (status == 0) return true;
      return status == 408 || status == 416 || status == 429 || status >= 500;
    }
    return false;
  }

  /// Downloads one surah for [reciter]; reports progress and honours [cancelToken].
  ///
  /// Interrupted transfers resume: an existing `<target>.part` is continued
  /// with an HTTP `Range` request when the host honours it (206), and the
  /// transfer restarts from zero when it does not (200). The part survives a
  /// failure on purpose, so the retry below (and the next user attempt) resumes
  /// instead of re-downloading the whole surah.
  Future<File> downloadSurah({
    required ReciterRow reciter,
    required int surahNumber,
    void Function(int received, int total)? onProgress,
    DownloadCancelToken? cancelToken,
  }) async {
    final token = cancelToken?.dioToken;
    try {
      return await _downloadAttempt(
        reciter: reciter,
        surahNumber: surahNumber,
        onProgress: onProgress,
        cancelToken: token,
      );
    } on Object catch (error) {
      final cancelled = cancelToken?.isCancelled ?? false;
      final delay = retryDelay;
      if (cancelled || delay == null || !_isRetryable(error)) rethrow;
      // One resume retry: a flaky CDN hop must not cost the whole file.
      await Future<void>.delayed(delay);
      if (cancelToken?.isCancelled ?? false) rethrow;
      return _downloadAttempt(
        reciter: reciter,
        surahNumber: surahNumber,
        onProgress: onProgress,
        cancelToken: token,
      );
    }
  }

  Future<File> _downloadAttempt({
    required ReciterRow reciter,
    required int surahNumber,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final target = await _targetFile(reciter.id, surahNumber);
    final part = File('${target.path}.part');
    final url = surahAudioUrl(reciter.server, surahNumber);
    final host = Uri.parse(url).host;
    var resumeFrom = 0;
    if (!_hostsWithoutRange.contains(host) && await part.exists()) {
      resumeFrom = await part.length();
    }
    await _registry.mark(reciter.id, surahNumber, DownloadStatus.downloading,
        resumeFrom, target.path);
    try {
      final res = await _fetchTrustedRedirects(
        Uri.parse(url),
        cancelToken: cancelToken,
        rangeFrom: resumeFrom,
      );
      final contentType =
          res.headers.value(Headers.contentTypeHeader)?.toLowerCase().trim();
      if (contentType != null && contentType.contains('html')) {
        throw DownloadFailure.permanent(
            'audio response is an HTML page, not an audio stream');
      }
      final status = res.statusCode ?? 0;
      final declared =
          int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? '') ??
              0;
      var total = declared;
      var received = 0;
      var append = false;
      if (resumeFrom > 0) {
        if (status == 206) {
          final contentRange =
              res.headers.value(HttpHeaders.contentRangeHeader);
          final start = _rangeStart(contentRange);
          if (start != resumeFrom) {
            // The host resumed somewhere else: the prefix is unusable, so
            // discard it and let the retry start over.
            await part.delete();
            throw DownloadFailure('host returned an unexpected range start');
          }
          append = true;
          received = resumeFrom;
          // `bytes N-M/*` means the host did not state the full size: keep it
          // unknown (0) so the completeness/oversize checks are skipped rather
          // than comparing a full-file offset against a remaining length.
          total = _totalFromContentRange(contentRange) ?? 0;
        } else {
          // The host ignored the Range header: remember it so the next
          // attempt does not waste a round-trip, and start from zero.
          _hostsWithoutRange.add(host);
        }
      }
      final throttle = ProgressThrottle();
      final body = res.data;
      if (body == null) throw DownloadFailure('empty audio response');
      final sink =
          part.openWrite(mode: append ? FileMode.append : FileMode.write);
      try {
        await for (final chunk in body.stream) {
          received += chunk.length;
          if (received > maxAcceptedBytes(total)) {
            throw DownloadFailure.permanent(
                'audio stream exceeded its declared size');
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
      await _registry.mark(
          reciter.id, surahNumber, DownloadStatus.done, size, promoted.path);
      return promoted;
    } on Object catch (error) {
      final cancelled = cancelToken?.isCancelled ?? false;
      // A cancel discards the transfer, and a 416 means the stored prefix no
      // longer matches the resource: drop the staging file in both cases. Any
      // other failure keeps it as resume material.
      if (cancelled ||
          (error is DioException && error.response?.statusCode == 416)) {
        if (await part.exists()) await part.delete();
      }
      await _registry.mark(
          reciter.id, surahNumber, DownloadStatus.failed, 0, target.path);
      if (!cancelled && isOutOfSpaceError(error)) {
        throw DownloadFailure.outOfSpace();
      }
      rethrow;
    }
  }

  /// The first byte of a `Content-Range: bytes <start>-<end>/<total>` header.
  static int? _rangeStart(String? value) {
    final match = RegExp(r'bytes\s+(\d+)-').firstMatch(value ?? '');
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// The complete size of a `Content-Range: bytes <start>-<end>/<total>` header.
  static int? _totalFromContentRange(String? value) {
    final match = RegExp(r'/(\d+)\s*$').firstMatch(value ?? '');
    return match == null ? null : int.tryParse(match.group(1)!);
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
      } on Object catch (error) {
        // The recovery rename failed; the ORIGINAL promote failure is the
        // one worth reporting, but keep a trace of the recovery attempt.
        appLog(
          'download promote recovery failed',
          name: 'quran_yahdi/downloads',
          error: error.runtimeType,
        );
      }
      rethrow;
    }
    if (await backup.exists()) await backup.delete();
    return swapped;
  }

  /// True when the surah finished downloading for that reciter.
  Future<bool> isDownloaded(String rowId, int surahNumber) =>
      _registry.isDownloaded(rowId, surahNumber);

  /// Path of the downloaded file, or null when it is not downloaded.
  Future<String?> downloadedPath(String rowId, int surahNumber) =>
      _registry.downloadedPath(rowId, surahNumber);

  /// Deletes the downloaded file and forgets the download row.
  Future<void> removeDownload(String rowId, int surahNumber) =>
      _registry.forget(rowId, surahNumber);

  /// All completed-download rows (used by the queue cubit on startup).
  Future<List<Download>> listDone() => _registry.listDone();
}
