import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/adhan_preferences.dart';
import 'package:quran_yahdi/features/notifications/data/adhan_preferences_impl.dart';

import 'support/test_db.dart';

void main() {
  group('global adhan', () {
    test('defaults to the default track when nothing is stored', () async {
      final AdhanPreferences prefs = AdhanPreferencesImpl(newTestDb());
      expect(await prefs.adhanId(), kDefaultAdhanId);
    });

    test('a selected track persists and round-trips', () async {
      final AdhanPreferences prefs = AdhanPreferencesImpl(newTestDb());
      await prefs.setAdhanId('omar_hisham');
      expect(await prefs.adhanId(), 'omar_hisham');
    });

    test('an unknown stored id resolves to the default', () async {
      final AdhanPreferences prefs = AdhanPreferencesImpl(newTestDb());
      await prefs.setAdhanId('removed_in_a_future_build');
      expect(await prefs.adhanId(), kDefaultAdhanId);
    });
  });

  group('fajr override', () {
    test('is null ("same as default") until it is set', () async {
      final AdhanPreferences prefs = AdhanPreferencesImpl(newTestDb());
      expect(await prefs.fajrAdhanId(), isNull);
    });

    test('a stored override round-trips', () async {
      final AdhanPreferences prefs = AdhanPreferencesImpl(newTestDb());
      await prefs.setFajrAdhanId('khushu');
      expect(await prefs.fajrAdhanId(), 'khushu');
    });

    test('clearing the override restores "same as default"', () async {
      final AdhanPreferences prefs = AdhanPreferencesImpl(newTestDb());
      await prefs.setFajrAdhanId('khushu');
      await prefs.setFajrAdhanId(null);
      expect(await prefs.fajrAdhanId(), isNull);
    });

    test('an unknown stored override resolves to null, not a dead id',
        () async {
      final AdhanPreferences prefs = AdhanPreferencesImpl(newTestDb());
      await prefs.setFajrAdhanId('removed_in_a_future_build');
      expect(await prefs.fajrAdhanId(), isNull);
    });
  });

  group('isolation', () {
    test('the global and fajr choices are stored independently', () async {
      final AdhanPreferences prefs = AdhanPreferencesImpl(newTestDb());
      await prefs.setAdhanId('islam_sobhy');
      expect(await prefs.fajrAdhanId(), isNull);
      await prefs.setFajrAdhanId('khushu');
      expect(await prefs.adhanId(), 'islam_sobhy');
    });
  });
}
