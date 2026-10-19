import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';

void main() {
  final service = HijriService();

  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  test('roundtrip: gregorian → hijri → gregorian is EXACT (no ±1 tolerance)',
      () {
    final samples = [
      DateTime(2026, 10, 15),
      DateTime(2025, 3, 1),
      DateTime(2027, 7, 20),
      DateTime(2024, 12, 31),
    ];
    for (final sample in samples) {
      final hijri = service.fromGregorian(sample);
      final back = service.toGregorian(hijri.hYear, hijri.hMonth, hijri.hDay);
      expect(dateOnly(back), dateOnly(sample), reason: 'roundtrip $sample');
    }
  });

  test('hijri year for 2026-10-15 is in {1447, 1448}', () {
    final hijri = service.fromGregorian(DateTime(2026, 10, 15));
    expect({1447, 1448}, contains(hijri.hYear));
  });

  test('every month length of hijri year 1447 is 29 or 30', () {
    for (var month = 1; month <= 12; month++) {
      final length = service.daysInMonth(1447, month);
      expect({29, 30}, contains(length), reason: 'month $month length $length');
    }
  });

  test('known span ordering: 1447 starts before 1448', () {
    final start1447 = service.toGregorian(1447, 1, 1);
    final start1448 = service.toGregorian(1448, 1, 1);
    expect(start1447.isBefore(start1448), isTrue);
  });
}
