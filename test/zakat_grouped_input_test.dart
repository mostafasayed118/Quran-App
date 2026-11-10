import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/zakat/data/zakat_calculator.dart';

void main() {
  group('parseDecimal grouped thousands', () {
    test('a lone comma group reads as thousands, not a decimal fraction', () {
      expect(parseDecimal('1,000'), 1000);
      expect(parseDecimal('12,345'), 12345);
      expect(parseDecimal('1,234,567'), 1234567);
    });

    test('the Arabic thousands separator alone reads as thousands', () {
      expect(parseDecimal('١٬٠٠٠'), 1000);
      expect(parseDecimal('١٢٬٣٤٥'), 12345);
    });

    test('short comma fractions keep their decimal meaning', () {
      expect(parseDecimal('1,5'), 1.5);
      expect(parseDecimal('1,00'), 1.0);
      expect(parseDecimal('0,25'), 0.25);
    });

    test('mixed separators still strip the thousands group', () {
      expect(parseDecimal('1,234.5'), 1234.5);
      expect(parseDecimal('1.234,5'), 1234.5);
    });
  });
}
