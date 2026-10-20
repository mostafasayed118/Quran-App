import 'dart:async';
import 'dart:developer' as dev;

/// F-D1 fail-open boot gate: runs [init] with at most [timeout] to complete,
/// so a plugin that hangs (or fails) can never stall app startup. On timeout
/// or any error the failure is logged to `quran_yahdi/boot` and `null` is
/// returned — boot proceeds fail-open. Never throws; a late completion of
/// [init] after the timeout is discarded cleanly (no unhandled async error).
Future<T?> failOpenBootInit<T>(
  String label,
  Future<T> Function() init, {
  required Duration timeout,
}) async {
  try {
    return await init().timeout(timeout);
  } on TimeoutException {
    dev.log(
      'boot init "$label" exceeded its ${timeout.inMilliseconds}ms bound — continuing fail-open',
      name: 'quran_yahdi/boot',
    );
    return null;
  } on Object catch (error, stackTrace) {
    dev.log(
      'boot init "$label" failed: $error — continuing fail-open',
      name: 'quran_yahdi/boot',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}
