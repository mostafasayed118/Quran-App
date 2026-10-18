/// Locale-tolerant decimal parsing: accepts `,` and `.` as either the
/// decimal or the thousands separator (last separator wins). Arabic-Indic
/// digits and separators (٠-٩، ٫، ٬) are normalized first so an Arabic
/// keyboard entry parses instead of silently collapsing to 0.
double parseDecimal(String raw) {
  final s = _toWesternNumerals(raw.trim()).replaceAll(' ', '');
  if (s.isEmpty) return 0;
  final hasComma = s.contains(',');
  final hasDot = s.contains('.');
  var normalized = s;
  if (hasComma && hasDot) {
    final decimalSep = s.lastIndexOf(',') > s.lastIndexOf('.') ? ',' : '.';
    final thousandsSep = decimalSep == ',' ? '.' : ',';
    normalized = s.replaceAll(thousandsSep, '').replaceFirst(decimalSep, '.');
  } else if (hasComma) {
    normalized = s.replaceAll(',', '.');
  }
  return double.tryParse(normalized) ?? 0;
}

/// Maps Arabic-Indic digits (٠-٩) and the Arabic decimal/thousands
/// separators (٫/٬) to their western equivalents.
String _toWesternNumerals(String s) {
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(rune - 0x0660 + 0x30);
    } else if (rune == 0x066B) {
      buffer.write('.');
    } else if (rune == 0x066C) {
      buffer.write(',');
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

class ZakatInput {
  const ZakatInput({
    this.goldGrams = 0,
    this.silverGrams = 0,
    this.cash = 0,
    this.debts = 0,
    this.nisabBySilver = false,
  });

  final double goldGrams;
  final double silverGrams;
  final double cash;
  final double debts;
  final bool nisabBySilver;
}

class ZakatResult {
  const ZakatResult({
    required this.zakatable,
    required this.nisabValue,
    required this.due,
    required this.amount,
  });

  final double zakatable;
  final double nisabValue;
  final bool due;
  final double amount;
}

class ZakatCalculator {
  const ZakatCalculator();

  /// Locked v1 constants (PM decision, cited on the screen).
  static const double goldNisabGrams = 87.48;
  static const double silverNisabGrams = 612.36;
  static const double zakatRate = 0.025;

  ZakatResult compute(
    ZakatInput input, {
    required double goldPricePerGram,
    required double silverPricePerGram,
  }) {
    final zakatable = input.cash +
        input.goldGrams * goldPricePerGram +
        input.silverGrams * silverPricePerGram -
        input.debts;
    final nisabValue = input.nisabBySilver
        ? silverNisabGrams * silverPricePerGram
        : goldNisabGrams * goldPricePerGram;
    final due = zakatable > 0 && zakatable >= nisabValue;
    return ZakatResult(
      zakatable: zakatable,
      nisabValue: nisabValue,
      due: due,
      amount: due ? zakatable * zakatRate : 0,
    );
  }
}
