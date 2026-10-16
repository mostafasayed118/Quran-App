import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/recitation/playback/background_init_guard.dart';

void main() {
  group('BackgroundInitGuard', () {
    test('returns true and marks active when init completes', () async {
      final ok = await BackgroundInitGuard.attempt(() async {});
      expect(ok, isTrue);
      expect(BackgroundInitGuard.active, isTrue);
    });

    test('swallows an init failure and reports inactive', () async {
      final ok = await BackgroundInitGuard.attempt(
        () async => throw StateError('service unavailable'),
      );
      expect(ok, isFalse);
      expect(BackgroundInitGuard.active, isFalse);
    });

    test('recovers on a later successful attempt', () async {
      await BackgroundInitGuard.attempt(
        () async => throw StateError('first attempt failed'),
      );
      final ok = await BackgroundInitGuard.attempt(() async {});
      expect(ok, isTrue);
      expect(BackgroundInitGuard.active, isTrue);
    });
  });
}
