import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/utils/hour_minute.dart';

void main() {
  test('accepts H:mm and HH:mm', () {
    expect(parseHourMinute('9:05'), (9, 5));
    expect(parseHourMinute('09:05'), (9, 5));
  });

  test('trims surrounding whitespace', () {
    expect(parseHourMinute(' 9:05 '), (9, 5));
  });

  test('rejects out-of-range values', () {
    expect(parseHourMinute('24:00'), isNull);
    expect(parseHourMinute('9:60'), isNull);
  });

  test('rejects one-digit minutes', () {
    expect(parseHourMinute('9:5'), isNull);
  });

  test('rejects empty, null and extra segments', () {
    expect(parseHourMinute(''), isNull);
    expect(parseHourMinute(null), isNull);
    expect(parseHourMinute('9:05:00'), isNull);
  });
}
