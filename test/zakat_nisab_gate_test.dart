import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/zakat/data/zakat_calculator.dart';

void main() {
  const calculator = ZakatCalculator();

  test('blank active silver price with positive cash → no verdict', () {
    final result = calculator.compute(
      const ZakatInput(cash: 1000, nisabBySilver: true),
      goldPricePerGram: 0,
      silverPricePerGram: 0,
    );
    expect(result.nisabValue, 0);
    expect(result.zakatable, 1000);
    expect(result.due, isFalse);
    expect(result.amount, 0);
  });

  test('blank active gold price with positive cash → no verdict', () {
    final result = calculator.compute(
      const ZakatInput(cash: 1000, nisabBySilver: false),
      goldPricePerGram: 0,
      silverPricePerGram: 0,
    );
    expect(result.nisabValue, 0);
    expect(result.zakatable, 1000);
    expect(result.due, isFalse);
    expect(result.amount, 0);
  });
}
