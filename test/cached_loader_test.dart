import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/cached_loader.dart';

void main() {
  test('concurrent callers share one in-flight load and its result', () async {
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

  test('a success is cached across later calls', () async {
    var invocations = 0;
    final loader = CachedLoader<String>(() async {
      invocations++;
      return 'value';
    });

    expect(await loader.load(), 'value');
    expect(await loader.load(), 'value');
    expect(invocations, 1);
  });

  test('a failure clears the cache, rethrows, and the next call retries',
      () async {
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

  test('concurrent callers of a failing load all see the error, then retry',
      () async {
    var invocations = 0;
    final gate = Completer<void>();
    final loader = CachedLoader<int>(() async {
      invocations++;
      if (invocations == 1) {
        await gate.future;
        throw StateError('first load fails');
      }
      return 1;
    });

    final first = loader.load();
    final second = loader.load();
    expect(invocations, 1);
    gate.complete();

    await expectLater(first, throwsStateError);
    await expectLater(second, throwsStateError);
    expect(await loader.load(), 1);
    expect(invocations, 2);
  });
}
