import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/prayer_name.dart';

void main() {
  group('catalog integrity', () {
    test('ids are unique, lowercase and raw-resource safe', () {
      final ids = kAdhanCatalog.map((track) => track.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
      for (final id in ids) {
        expect(
          RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id),
          isTrue,
          reason: 'not a safe id: $id',
        );
      }
    });

    test('every track ships both a full file and a clip', () {
      for (final track in kAdhanCatalog) {
        expect(
          File(track.assetPath).existsSync(),
          isTrue,
          reason: 'missing full asset: ${track.assetPath}',
        );
        expect(
          File(track.clipPath).existsSync(),
          isTrue,
          reason: 'missing clip asset: ${track.clipPath}',
        );
      }
    });

    test('every track has both display names and a positive duration', () {
      for (final track in kAdhanCatalog) {
        expect(track.nameAr.trim(), isNotEmpty, reason: track.id);
        expect(track.nameEn.trim(), isNotEmpty, reason: track.id);
        expect(track.durationSeconds, greaterThan(0), reason: track.id);
      }
    });

    test('the default track is present in the catalog', () {
      expect(
        kAdhanCatalog.any((track) => track.id == kDefaultAdhanId),
        isTrue,
      );
    });
  });

  group('resolution', () {
    test('an unknown or null id resolves to the default', () {
      expect(adhanById(null).id, kDefaultAdhanId);
      expect(adhanById('').id, kDefaultAdhanId);
      expect(adhanById('does_not_exist').id, kDefaultAdhanId);
    });

    test('a known id resolves to itself', () {
      final second = kAdhanCatalog[1];
      expect(adhanById(second.id).id, second.id);
    });

    test('fajr takes the override, other prayers take the global', () {
      expect(
        adhanIdForPrayer(
          prayer: PrayerName.fajr,
          globalId: 'omar_hisham',
          fajrId: 'khushu',
        ),
        'khushu',
      );
      expect(
        adhanIdForPrayer(
          prayer: PrayerName.fajr,
          globalId: 'omar_hisham',
          fajrId: null,
        ),
        'omar_hisham',
      );
      expect(
        adhanIdForPrayer(
          prayer: PrayerName.isha,
          globalId: 'omar_hisham',
          fajrId: 'khushu',
        ),
        'omar_hisham',
      );
    });

    test('an unknown fajr override falls back to the global choice', () {
      expect(
        adhanIdForPrayer(
          prayer: PrayerName.fajr,
          globalId: 'omar_hisham',
          fajrId: 'removed_in_a_future_build',
        ),
        'omar_hisham',
      );
    });
  });

  group('notification channel', () {
    test('every track maps to a distinct channel id', () {
      final channelIds = kAdhanCatalog.map(adhanChannelId).toSet();
      expect(channelIds.length, kAdhanCatalog.length);
    });

    test('a channel id is namespaced per track', () {
      final track = kAdhanCatalog.first;
      expect(adhanChannelId(track), 'quran_yahdi_adhan_${track.id}');
    });
  });
}
