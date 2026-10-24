import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/zakat/data/zakat_calculator.dart';

void main() {
  group('parseDecimal non-finite and negative input', () {
    test('non-finite literals collapse to zero', () {
      expect(parseDecimal('NaN'), 0);
      expect(parseDecimal('Infinity'), 0);
      expect(parseDecimal('-Infinity'), 0);
      expect(parseDecimal('1e999'), 0);
    });

    test('negative values collapse to zero', () {
      expect(parseDecimal('-5'), 0);
      expect(parseDecimal('-0.25'), 0);
    });

    test('finite non-negative values still parse', () {
      expect(parseDecimal('1234.5'), 1234.5);
      expect(parseDecimal('1,234.5'), 1234.5);
      expect(parseDecimal('١٢٣٫٤٥'), 123.45);
      expect(parseDecimal(' 42 '), 42);
      expect(parseDecimal(''), 0);
      expect(parseDecimal('abc'), 0);
    });
  });
}
