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
  String get toArabicIndic {
    final buffer = StringBuffer();
    for (final char in toString().split('')) {
      final digit = int.tryParse(char);
      buffer.write(digit == null ? char : _arabicIndicDigits[digit]);
    }
    return buffer.toString();
  }
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

/// H:mm clock label with Arabic-Indic digits (call-site transform, W3).
String formatHm(DateTime time) {
  final clock = '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
  return clock.toArabicIndicDigits;
}

/// H:mm label for a Duration (call-site transform, W3).
String formatDurationHm(Duration duration) {
  final clock = '${duration.inHours.toString().padLeft(2, '0')}:'
      '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}';
  return clock.toArabicIndicDigits;
}
