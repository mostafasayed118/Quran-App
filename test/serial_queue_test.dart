import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/utils/serial_queue.dart';

void main() {
  test('tasks run in submission order, even when the first is slow', () async {
    final queue = SerialQueue();
    final first = Completer<void>();
    final order = <String>[];

    final a = queue.add(() async {
      await first.future;
      order.add('a');
      return 'a';
    });
    final b = queue.add(() async {
      order.add('b');
      return 'b';
    });

    await Future<void>.delayed(Duration.zero);
    expect(order, isEmpty, reason: 'b must not start while a is pending');

    first.complete();
    expect(await a, 'a');
    expect(await b, 'b');
    expect(order, <String>['a', 'b']);
  });

  test(
    'a failing task reaches its caller and does not block the next',
    () async {
      final queue = SerialQueue();

      final failed = queue.add<void>(() async => throw StateError('boom'));
      final next = queue.add(() async => 42);

      await expectLater(failed, throwsStateError);
      expect(await next, 42);
    },
  );

  test('a failure that is not awaited does not poison the queue', () async {
    final queue = SerialQueue();

    final failed = queue.add<void>(() async => throw StateError('boom'));
    // The caller ignored the returned future; the queue tail still settles.
    unawaited(failed.catchError((Object _) {}));

    expect(await queue.add(() async => 'ok'), 'ok');
  });
}
