import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/prayer_skin.dart';
import 'package:quran_yahdi/core/theme/prayer_skin_controller.dart';
import 'package:quran_yahdi/features/settings/data/prayer_skin_repository.dart';

import 'support/test_db.dart';

class _ThrowingSource implements PrayerSkinSource {
  @override
  Future<PrayerSkinMode> load() async => throw StateError('unreadable');

  @override
  Future<void> save(PrayerSkinMode mode) async => throw StateError('locked');
}

class _MemorySource implements PrayerSkinSource {
  PrayerSkinMode stored = PrayerSkinMode.fixed;

  @override
  Future<PrayerSkinMode> load() async => stored;

  @override
  Future<void> save(PrayerSkinMode mode) async => stored = mode;
}

void main() {
  group('PrayerSkinMode.fromCode', () {
    test('round-trips both persisted codes', () {
      for (final mode in PrayerSkinMode.values) {
        expect(PrayerSkinMode.fromCode(mode.code), mode);
      }
    });

    test('an unknown or missing code is fixed', () {
      expect(PrayerSkinMode.fromCode(null), PrayerSkinMode.fixed);
      expect(PrayerSkinMode.fromCode(''), PrayerSkinMode.fixed);
      expect(PrayerSkinMode.fromCode('seasonal'), PrayerSkinMode.fixed);
    });
  });

  group('PrayerSkinRepository', () {
    late AppDatabase db;

    setUp(() => db = newTestDb());

    test('nothing stored reads as fixed', () async {
      expect(await PrayerSkinRepository(db).load(), PrayerSkinMode.fixed);
    });

    test('follow survives a write and a fresh read', () async {
      await PrayerSkinRepository(db).save(PrayerSkinMode.follow);
      expect(await PrayerSkinRepository(db).load(), PrayerSkinMode.follow);
    });

    test('the key is device-scoped (never restored from a backup)', () {
      expect(PrayerSkinRepository.key, 'prayer_skin_mode');
    });
  });

  group('PrayerSkinController', () {
    test('starts fixed and follows the stored choice after load', () async {
      final source = _MemorySource()..stored = PrayerSkinMode.follow;
      final controller = PrayerSkinController(source);
      addTearDown(controller.dispose);

      expect(controller.mode, PrayerSkinMode.fixed);
      expect(controller.followsPrayer, isFalse);
      expect(controller.loaded, isFalse);

      await controller.load();

      expect(controller.mode, PrayerSkinMode.follow);
      expect(controller.followsPrayer, isTrue);
      expect(controller.loaded, isTrue);
    });

    test('a failed read keeps fixed', () async {
      final controller = PrayerSkinController(_ThrowingSource());
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.mode, PrayerSkinMode.fixed);
      expect(controller.loaded, isTrue);
    });

    test('switching notifies immediately and persists', () async {
      final source = _MemorySource();
      final controller = PrayerSkinController(source);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setMode(PrayerSkinMode.follow);

      expect(controller.mode, PrayerSkinMode.follow);
      expect(notifications, 1);
      expect(source.stored, PrayerSkinMode.follow);

      // A no-op switch does not rebuild the app root.
      await controller.setMode(PrayerSkinMode.follow);
      expect(notifications, 1);
    });

    test('a failed write keeps the in-memory choice', () async {
      final controller = PrayerSkinController(_ThrowingSource());
      addTearDown(controller.dispose);

      await controller.setMode(PrayerSkinMode.follow);

      expect(controller.mode, PrayerSkinMode.follow);
    });
  });
}
