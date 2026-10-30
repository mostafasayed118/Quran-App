/// Locale-tolerant decimal parsing: accepts `,` and `.` as either the
/// decimal or the thousands separator (last separator wins). Arabic-Indic
/// digits and separators (٠-٩، ٫، ٬) are normalized first so an Arabic
/// keyboard entry parses instead of silently collapsing to 0.
const int _arabicIndicZero = 0x0660;
const int _arabicIndicNine = 0x0669;
const int _arabicDecimalSeparator = 0x066B;
const int _arabicThousandsSeparator = 0x066C;
const int _asciiZero = 0x30;

double parseDecimal(String raw) => parseDecimalOrNull(raw) ?? 0;

/// Parses [raw] like [parseDecimal], but returns null when the text is not a
/// finite, non-negative number. The UI uses this to reject invalid input
/// instead of silently treating it as zero.
double? parseDecimalOrNull(String raw) {
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
  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite || parsed < 0) return null;
  return parsed;
}

/// Maps Arabic-Indic digits (٠-٩) and the Arabic decimal/thousands
/// separators (٫/٬) to their western equivalents.
String _toWesternNumerals(String s) {
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    if (rune >= _arabicIndicZero && rune <= _arabicIndicNine) {
      buffer.writeCharCode(rune - _arabicIndicZero + _asciiZero);
    } else if (rune == _arabicDecimalSeparator) {
      buffer.write('.');
    } else if (rune == _arabicThousandsSeparator) {
      buffer.write(',');
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// The assets and debts used to compute zakat.
class ZakatInput {
  const ZakatInput({
    this.goldGrams = 0,
    this.silverGrams = 0,
    this.cash = 0,
    this.debts = 0,
    this.nisabBySilver = false,
  });

  /// Held gold, in grams.
  final double goldGrams;

  /// Held silver, in grams.
  final double silverGrams;

  /// Cash and cash-like assets.
  final double cash;

  /// Deductible debts.
  final double debts;

  /// Use the silver nisab instead of the gold one.
  final bool nisabBySilver;
}

/// The computed zakat.
class ZakatResult {
  const ZakatResult({
    required this.zakatable,
    required this.nisabValue,
    required this.due,
    required this.amount,
  });

  /// Wealth left after deducting debts.
  final double zakatable;

  /// Value of the nisab threshold that applies.
  final double nisabValue;

  /// True when the wealth reaches the nisab, so zakat is due.
  final bool due;

  /// Zakat amount due; zero when [due] is false.
  final double amount;
}

/// Computes zakat from the entered assets.
class ZakatCalculator {
  const ZakatCalculator();

  /// Locked v1 constants (PM decision, cited on the screen).
  static const double goldNisabGrams = 87.48;

  /// Silver nisab threshold in grams (612.36 g).
  static const double silverNisabGrams = 612.36;

  /// Zakat rate applied to the zakatable wealth (2.5%).
  static const double zakatRate = 0.025;

  /// Computes the zakat for [input] using the given metal prices.
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
    final due = nisabValue > 0 && zakatable > 0 && zakatable >= nisabValue;
    return ZakatResult(
      zakatable: zakatable,
      nisabValue: nisabValue,
      due: due,
      amount: due ? zakatable * zakatRate : 0,
    );
  }
}
