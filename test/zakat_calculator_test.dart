import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/zakat/data/zakat_calculator.dart';

void main() {
  const calculator = ZakatCalculator();

  test('below silver nisab → due=false, amount=0', () {
    final result = calculator.compute(
      const ZakatInput(silverGrams: 50, cash: 100, nisabBySilver: true),
      goldPricePerGram: 1,
      silverPricePerGram: 1,
    );
    expect(result.zakatable, 150);
    expect(result.nisabValue, closeTo(612.36, 1e-9));
    expect(result.due, isFalse);
    expect(result.amount, 0);
  });

  test('gold nisab mode (default) → nisabValue = 87.48 × goldPrice', () {
    final result = calculator.compute(
      const ZakatInput(goldGrams: 100, nisabBySilver: false),
      goldPricePerGram: 2,
      silverPricePerGram: 1,
    );
    expect(result.zakatable, 200);
    expect(result.nisabValue, closeTo(87.48 * 2, 1e-9));
    expect(result.due, isTrue);
    expect(result.amount, closeTo(200 * 0.025, 1e-9));
  });

  test('below-gold/above-silver with silver default → due, 2.5% amount', () {
    final result = calculator.compute(
      const ZakatInput(cash: 1000, nisabBySilver: true),
      goldPricePerGram: 1,
      silverPricePerGram: 1,
    );
    expect(result.zakatable, 1000);
    expect(result.nisabValue, closeTo(612.36, 1e-9));
    expect(result.due, isTrue);
    expect(result.amount, closeTo(25, 1e-9));
  });

  test('debts subtract from the zakatable base', () {
    final result = calculator.compute(
      const ZakatInput(cash: 2000, debts: 500, nisabBySilver: true),
      goldPricePerGram: 1,
      silverPricePerGram: 1,
    );
    expect(result.zakatable, 1500);
    expect(result.due, isTrue);
    expect(result.amount, closeTo(37.5, 1e-9));
  });

  test('parseDecimal tolerates both separators', () {
    expect(parseDecimal('1,000.50'), 1000.5);
    expect(parseDecimal('1000,50'), 1000.5);
    expect(parseDecimal('1.000,50'), 1000.5);
    expect(parseDecimal('250'), 250);
    expect(parseDecimal(' '), 0);
    expect(parseDecimal('abc'), 0);
  });
}
