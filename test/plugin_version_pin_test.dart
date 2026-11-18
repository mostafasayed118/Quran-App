import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The alarm probe reconstructs a `PendingIntent` identity that is private to
/// `flutter_local_notifications`. The identity is version-specific, so a silent
/// upgrade would invalidate the device verification without changing a line of
/// our code. Pin the locked version here to force a re-check on any bump.
void main() {
  test('flutter_local_notifications stays at the verified version', () {
    final lines = File('pubspec.lock').readAsLinesSync();
    var version = '';
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim() != 'flutter_local_notifications:') continue;
      for (var j = i + 1; j < lines.length && lines[j].startsWith(' '); j++) {
        final trimmed = lines[j].trim();
        if (trimmed.startsWith('version:')) {
          version = trimmed.substring('version:'.length).trim();
          version = version.replaceAll('"', '');
          break;
        }
      }
      break;
    }
    expect(
      version,
      isNotEmpty,
      reason: 'pubspec.lock has no flutter_local_notifications version',
    );
    expect(
      version,
      '22.3.2',
      reason:
          'the alarm probe identity was verified against 22.3.2 only. '
          'Re-read getBroadcastPendingIntent() in the new plugin source, '
          're-run the device probe, then update this pin.',
    );
  });
}
