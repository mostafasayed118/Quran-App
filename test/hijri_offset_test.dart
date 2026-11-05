import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';

void main() {
  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  test('a positive offset shifts the Hijri date forward by one day', () {
    final base = HijriService();
    final shifted = HijriService(offsetDays: 1);
    final date = DateTime(2026, 11, 5);

    final actual = shifted.fromGregorian(date);
    final expected = base.fromGregorian(DateTime(2026, 11, 6));

    expect(
      (actual.hYear, actual.hMonth, actual.hDay),
      (expected.hYear, expected.hMonth, expected.hDay),
    );
  });

  test('a negative offset shifts the Hijri date backward by one day', () {
    final base = HijriService();
    final shifted = HijriService(offsetDays: -1);
    final date = DateTime(2026, 11, 5);

    final actual = shifted.fromGregorian(date);
    final expected = base.fromGregorian(DateTime(2026, 11, 4));

    expect(
      (actual.hYear, actual.hMonth, actual.hDay),
      (expected.hYear, expected.hMonth, expected.hDay),
    );
  });

  test('the offset round-trips Gregorian → Hijri → Gregorian exactly', () {
    for (final offset in const [-2, -1, 0, 1, 2]) {
      final service = HijriService(offsetDays: offset);
      for (final sample in [
        DateTime(2026, 10, 15),
        DateTime(2024, 12, 31),
        DateTime(2027, 3, 1),
      ]) {
        final hijri = service.fromGregorian(sample);
        final back = service.toGregorian(hijri.hYear, hijri.hMonth, hijri.hDay);
        expect(
          dateOnly(back),
          dateOnly(sample),
          reason: 'offset $offset round-trip $sample',
        );
      }
    }
  });

  test('the offset is clamped to the supported range', () {
    final service = HijriService(offsetDays: 9);
    expect(service.offsetDays, HijriService.maxOffsetDays);

    service.offsetDays = -9;
    expect(service.offsetDays, HijriService.minOffsetDays);

    service.offsetDays = 1;
    expect(service.offsetDays, 1);
  });

  test('month length and month name stay calendar-pure', () {
    final base = HijriService();
    final shifted = HijriService(offsetDays: 2);

    expect(shifted.daysInMonth(1447, 9), base.daysInMonth(1447, 9));
    expect(shifted.monthName(1447, 9), base.monthName(1447, 9));
  });
}
