const List<String> _arabicIndicDigits = [
  '٠',
  '١',
  '٢',
  '٣',
  '٤',
  '٥',
  '٦',
  '٧',
  '٨',
  '٩',
];

extension ArabicIndicInt on int {
  /// Renders this int with Arabic-Indic digits (٠-٩).
  ///
  /// Delegates to the [String] mapping, so both extensions agree on every
  /// input — including negatives, where only the digits are converted and
  /// the minus sign is kept as-is.
  String get toArabicIndic => toString().toArabicIndicDigits;
}

extension ArabicIndicString on String {
  /// Maps every western digit inside this string to its Arabic-Indic form.
  String get toArabicIndicDigits {
    final buffer = StringBuffer();
    for (final char in split('')) {
      final digit = int.tryParse(char);
      buffer.write(digit == null ? char : _arabicIndicDigits[digit]);
    }
    return buffer.toString();
  }
}

extension WesternDigitsString on String {
  /// Maps every Arabic-Indic digit (٠-٩) inside this string to its western
  /// form; all other characters are kept as-is.
  String get toWesternDigits {
    final buffer = StringBuffer();
    for (final char in split('')) {
      final digit = _arabicIndicDigits.indexOf(char);
      buffer.write(digit == -1 ? char : digit);
    }
    return buffer.toString();
  }
}

/// H:mm clock label with Arabic-Indic digits (call-site transform, W3).
///
/// [arabicIndic] false returns the plain 'HH:mm' form — the format the
/// reminder planner parses, so a caller that PERSISTS a time must use it.
String formatHm(DateTime time, {bool arabicIndic = true}) {
  final clock = '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
  return arabicIndic ? clock.toArabicIndicDigits : clock;
}

/// H:mm label for a Duration (call-site transform, W3).
String formatDurationHm(Duration duration) {
  final clock = '${duration.inHours.toString().padLeft(2, '0')}:'
      '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}';
  return clock.toArabicIndicDigits;
}
