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
