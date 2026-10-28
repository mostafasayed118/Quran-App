import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:quran_yahdi/features/recitation/playback/just_audio_playback_service.dart';

/// The production service, read as text: `AudioPlayer` is a concrete
/// just_audio class, so the fire-and-forget contract is pinned at the seam
/// (`issuePlayRequest`) plus a source guard against restoring `await`.
final _serviceRelPath = p.join(
  'lib',
  'features',
  'recitation',
  'playback',
  'just_audio_playback_service.dart',
);

void main() {
  group('issuePlayRequest', () {
    test('returns while the play future is still pending', () async {
      final gate = Completer<void>();
      var issued = 0;

      issuePlayRequest(
        () {
          issued++;
          return gate.future;
        },
        operation: 'playback play request failed',
      );

      // Draining the microtask queue must not wait for playback to start.
      await Future<void>.delayed(Duration.zero);
      expect(issued, 1, reason: 'the play request must still be issued');
      expect(gate.isCompleted, isFalse,
          reason: 'the caller must not wait for the play future');

      gate.complete();
      await gate.future;
    });

    test('swallows a failing play future and reports it exactly once',
        () async {
      final logged = <String>[];
      Object? reportedError;
      final escaped = <Object>[];

      final body = runZonedGuarded<Future<void>>(
        () async {
          issuePlayRequest(
            () => Future<void>.error(
              StateError('play failed'),
              StackTrace.current,
            ),
            operation: 'playback resume request failed',
            log: (message, error, stackTrace) {
              logged.add(message);
              reportedError = error;
            },
          );
          await Future<void>.delayed(Duration.zero);
        },
        (error, stackTrace) => escaped.add(error),
      );
      await body;

      expect(logged, ['playback resume request failed'],
          reason: 'the injected log must receive the operation verbatim');
      expect(reportedError, isA<StateError>());
      expect(escaped, isEmpty,
          reason: 'a failing play future must never escape the helper');
    });
  });

  group('just_audio_playback_service source guard', () {
    test('issues playback through issuePlayRequest and never awaits play', () {
      final source = File(p.join(Directory.current.path, _serviceRelPath))
          .readAsStringSync();

      expect(source, contains('issuePlayRequest('));
      expect(source, isNot(contains('await _player.play()')),
          reason: 'play() resolves on pause/stop/completion, not on start');
      expect(source, isNot(contains('await _player.play(')),
          reason: 'play() resolves on pause/stop/completion, not on start');
      expect(source, contains("'playback play request failed'"));
      expect(source, contains("'playback resume request failed'"));
    });
  });
}
