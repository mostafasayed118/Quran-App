import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/cached_loader.dart';

void main() {
  test('a failed load surfaces the original stack trace', () async {
    final loader = CachedLoader<int>(() async {
      Error.throwWithStackTrace(
        StateError('boom'),
        StackTrace.fromString('marker_frame'),
      );
    });

    try {
      await loader.load();
      fail('expected the load to throw');
    } on StateError catch (_, stackTrace) {
      expect(stackTrace.toString(), contains('marker_frame'));
    }
  });

  test('the next load after a failure retries and succeeds', () async {
    var invocations = 0;
    final loader = CachedLoader<int>(() async {
      invocations++;
      if (invocations == 1) {
        throw StateError('boom');
      }
      return 42;
    });

    await expectLater(loader.load(), throwsStateError);
    expect(await loader.load(), 42);
    expect(invocations, 2);
  });

  test('concurrent loads share one invocation', () async {
    var invocations = 0;
    final gate = Completer<void>();
    final loader = CachedLoader<int>(() async {
      invocations++;
      await gate.future;
      return 7;
    });

    final first = loader.load();
    final second = loader.load();
    expect(invocations, 1);

    gate.complete();
    expect(await first, 7);
    expect(await second, 7);
    expect(invocations, 1);
  });
}
