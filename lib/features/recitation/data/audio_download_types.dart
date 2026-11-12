part of 'audio_downloader.dart';

/// Download transport budgets: a slow server must not hang a queued surah.
const Duration _connectTimeout = Duration(seconds: 15);
const Duration _receiveTimeout = Duration(minutes: 2);

/// Opaque cancellation handle for one download attempt.
///
/// The presentation layer owns this handle, never the transport token: the
/// queue must be able to abort a transfer without importing dio.
class DownloadCancelToken {
  /// Creates a handle that starts uncancelled.
  DownloadCancelToken() : _token = CancelToken();

  final CancelToken _token;

  /// The transport token; only the data layer may use it.
  CancelToken get dioToken => _token;

  /// Whether [cancel] has been called.
  bool get isCancelled => _token.isCancelled;

  /// Completes when [cancel] is called (used by test doubles).
  Future<void> get whenCancelled => _token.whenCancel;

  /// Aborts the transfer.
  void cancel([Object? reason]) => _token.cancel(reason);
}

/// Raised when a surah audio download cannot be completed.
class DownloadFailure implements Exception {
  /// A failure that may succeed on a second attempt (network, truncation).
  DownloadFailure(this.message)
      : retryable = true,
        outOfSpace = false;

  /// A failure the same request cannot fix (an HTML error page, a redirect
  /// chain, an unsupported scheme): retrying would only burn the queue.
  DownloadFailure.permanent(this.message)
      : retryable = false,
        outOfSpace = false;

  /// The write hit a full disk: the request is fine, the device is not.
  DownloadFailure.outOfSpace()
      : message = 'no space left on device',
        retryable = false,
        outOfSpace = true;

  /// Human-readable reason of the failure.
  final String message;

  /// Whether one more attempt is worth it.
  final bool retryable;

  /// Whether the transfer failed because the device has no free space.
  final bool outOfSpace;

  @override
  String toString() => 'DownloadFailure: $message';
}

/// Whether [error] (or the error a [DioException] wraps) reports a full disk.
///
/// ENOSPC is 28 on Android/Linux and ERROR_DISK_FULL is 112 on Windows; the
/// text check covers platforms whose code we cannot rely on.
bool isOutOfSpaceError(Object error) {
  if (error is FileSystemException) {
    final os = error.osError;
    final text = '${error.message} ${os?.message ?? ''}'.toLowerCase();
    return os?.errorCode == 28 ||
        os?.errorCode == 112 ||
        text.contains('no space left') ||
        text.contains('not enough space');
  }
  if (error is DioException && error.error != null) {
    return isOutOfSpaceError(error.error!);
  }
  return false;
}
