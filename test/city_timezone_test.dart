import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/utils/city_clock.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('every catalog city has a resolvable IANA zone', () {
    final raw = jsonDecode(
      File('assets/data/cities.json').readAsStringSync(),
    ) as List<dynamic>;
    expect(raw, hasLength(156));
    tzdata.initializeTimeZones();
    for (final item in raw) {
      final city = item as Map<String, dynamic>;
      final zone = city['timezone'] as String?;
      expect(zone, isNotNull, reason: '${city['id']} has no timezone');
      expect(
        () => tz.getLocation(zone!),
        returnsNormally,
        reason: '${city['id']} -> $zone',
      );
    }
  });

  test('the wall clock follows the city zone, not the device zone', () {
    final instant = DateTime.utc(2026, 1, 15, 12);
    expect(cityWallClock(instant, 'Africa/Cairo').hour, 14);
    expect(cityWallClock(instant, 'Europe/London').hour, 12);
    expect(cityWallClock(instant, 'Asia/Tokyo').hour, 21);
  });

  test('a null or unknown zone keeps the instant unchanged', () {
    final instant = DateTime.utc(2026, 1, 15, 12);
    expect(cityWallClock(instant, null), instant);
    expect(cityWallClock(instant, 'Not/AZone'), instant);
  });
}
