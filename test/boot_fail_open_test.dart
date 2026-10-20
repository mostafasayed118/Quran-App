import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/utils/boot_fail_open.dart';

void main() {
  group('failOpenBootInit', () {
    test('returns the init value when init succeeds', () async {
      final result = await failOpenBootInit(
        'ok',
        () async => 42,
        timeout: const Duration(milliseconds: 200),
      );
      expect(result, 42);
    });

    test('returns null when init throws before returning a future', () async {
      final result = await failOpenBootInit<int>(
        'sync-throw',
        () => throw StateError('boom'),
        timeout: const Duration(milliseconds: 200),
      );
      expect(result, isNull);
    });

    test('returns null when init fails asynchronously', () async {
      final result = await failOpenBootInit<int>(
        'async-throw',
        () async => throw StateError('boom'),
        timeout: const Duration(milliseconds: 200),
      );
      expect(result, isNull);
    });

    test('returns null after the timeout when init never resolves', () async {
      final result = await failOpenBootInit<int>(
        'hang',
        () => Completer<int>().future,
        timeout: const Duration(milliseconds: 20),
      );
      expect(result, isNull);
    });

    test(
      'discards a late completion after the timeout without unhandled errors',
      () async {
        final completer = Completer<int>();
        final result = await failOpenBootInit(
          'late',
          () => completer.future,
          timeout: const Duration(milliseconds: 20),
        );
        expect(result, isNull);

        completer.completeError(StateError('late boom'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
    );
  });
}
