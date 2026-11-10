import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps the log-hygiene net over `appLog` after the release gate landed.
///
/// `log_hygiene_test.dart` scans `dev.log(`, and after every call site moved to
/// `appLog(` it now only sees the helper itself. This test restores the
/// coverage at the new entry point and adds the structural guarantee the
/// privacy policy depends on: `dart:developer` is reached from exactly one
/// file, so a release build cannot log anything.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) =>
          file.path.endsWith('.dart') &&
          !file.path.endsWith('.g.dart') &&
          !file.path.endsWith('.freezed.dart'))
      .toList();

  test('only app_log.dart may call dev.log', () {
    for (final file in files) {
      final rel = file.path.replaceAll(r'\', '/');
      if (rel.endsWith('lib/core/utils/app_log.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('dev.log(')) {
          fail('$rel:${i + 1} calls dev.log directly — use appLog()');
        }
      }
    }
  });

  test('no appLog call logs a secret-like value', () {
    final secret = RegExp(
      r'(password|passphrase|secret|authorization|bearer|api[_-]?key|access[_-]?token)',
      caseSensitive: false,
    );
    for (final file in files) {
      final rel = file.path.replaceAll(r'\', '/');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('appLog(')) continue;
        // A call's arguments may span several lines.
        final window = lines.skip(i).take(8).join('\n');
        if (secret.hasMatch(window)) {
          fail('$rel:${i + 1} logs a secret-like value');
        }
      }
    }
  });

  test('the helper itself is release-gated', () {
    final source = File('lib/core/utils/app_log.dart').readAsStringSync();
    expect(source.contains('if (kReleaseMode) return;'), isTrue,
        reason: 'appLog must no-op in a release build: the privacy policy '
            'states that local logs are used during development only');
  });
}
