import 'arabic_numbers.dart';

const List<String> _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// Arabic date with Arabic-Indic digits, e.g. «٢٦ نوفمبر ٢٠٢٦».
///
/// Digit conversion alone does not localize month names, so the month is taken
/// from [_arabicMonths] and only the numbers go through [toArabicIndic].
String formatArabicDate(DateTime date) =>
    '${date.day.toArabicIndic} ${_arabicMonths[date.month - 1]} ${date.year.toArabicIndic}';
