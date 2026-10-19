import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/pack_reader.dart';

/// Scheduling contract of the read path: one decode per pack in flight
/// (single-flight) and at most one decode in flight globally (serialization).
void main() {
  test('concurrent reads of the same pack share ONE decode (single-flight)',
      () async {
    var calls = 0;
    final gate = Completer<dynamic>();
    final reader = PackReader(
      fileDecoder: (path) {
        calls++;
        return gate.future;
      },
      packPath: (packId) async => '/fake/$packId.json',
    );

    final first = reader.translationFor('same-pack', 1, 1);
    final second = reader.translationFor('same-pack', 1, 2);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Both readers are pending on the same gated decode.
    expect(calls, 1);

    gate.complete({
      'quran': [
        {'chapter': 1, 'verse': 1, 'text': 'one'},
        {'chapter': 1, 'verse': 2, 'text': 'two'},
      ],
    });

    expect(await first, 'one');
    expect(await second, 'two');
    expect(calls, 1);
  });

  test('decodes for different packs are serialized in start order', () async {
    final started = <String>[];
    final gates = <String, Completer<dynamic>>{
      'alpha': Completer<dynamic>(),
      'beta': Completer<dynamic>(),
    };
    final reader = PackReader(
      fileDecoder: (path) {
        final id = path.split('/').last.replaceAll('.json', '');
        started.add(id);
        return gates[id]!.future;
      },
      packPath: (packId) async => '/fake/$packId.json',
    );

    final alpha = reader.translationFor('alpha', 1, 1);
    final beta = reader.translationFor('beta', 1, 1);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // The second decode must not start while the first is still running.
    expect(started, <String>['alpha']);

    gates['alpha']!.complete({
      'quran': [
        {'chapter': 1, 'verse': 1, 'text': 'ALPHA'},
      ],
    });
    expect(await alpha, 'ALPHA');

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(started, <String>['alpha', 'beta']);

    gates['beta']!.complete({
      'quran': [
        {'chapter': 1, 'verse': 1, 'text': 'BETA'},
      ],
    });
    expect(await beta, 'BETA');
  });

  test('a failed decode does not wedge the decode queue', () async {
    var calls = 0;
    final reader = PackReader(
      fileDecoder: (path) async {
        calls++;
        if (path.contains('bad')) throw const FormatException('corrupt');
        return {
          'quran': [
            {'chapter': 1, 'verse': 1, 'text': 'OK'},
          ],
        };
      },
      packPath: (packId) async => '/fake/$packId.json',
    );

    expect(await reader.translationFor('bad', 1, 1), isNull);
    expect(await reader.translationFor('good', 1, 1), 'OK');
    expect(calls, 2);
  });
}
