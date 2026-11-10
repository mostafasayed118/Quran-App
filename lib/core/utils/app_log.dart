import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// The one logging entry point for the app.
///
/// **Silent in a release build.** `PRIVACY.md` states that local logs are used
/// during development only, and `dart:developer`'s `log` keeps writing to the
/// platform log (logcat / unified log) in release. Routing every call through
/// this helper is what actually enforces that claim, instead of relying on it.
///
/// Diagnostics stay fully available in debug and profile builds, which is where
/// they are used.
///
/// Call shape mirrors `dev.log`, so a call site reads the same:
/// `appLog('backup import failed', name: 'quran_yahdi/backup',
/// error: error.runtimeType, stackTrace: stackTrace)`.
///
/// Pass `error.runtimeType` rather than the exception object wherever the
/// message could embed user content or a path — a `jsonDecode` failure, for
/// example, quotes a snippet of the imported file.
void appLog(
  String message, {
  String? name,
  Object? error,
  StackTrace? stackTrace,
}) {
  if (kReleaseMode) return;
  dev.log(message, name: name ?? '', error: error, stackTrace: stackTrace);
}
