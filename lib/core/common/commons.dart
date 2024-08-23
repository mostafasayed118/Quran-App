import 'package:quran_app/core/utils/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

//! Save Settings
Future saveSettings() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('arabicFontSize', AppStrings.arabicFontSized.toInt());
  await prefs.setInt('mushafFontSize', AppStrings.mushafFontSized.toInt());
}

//! Get Settings
Future getSettings() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  try {
    AppStrings.arabicFontSized = prefs.getInt('arabicFontSize')!.toDouble();
    AppStrings.mushafFontSized = prefs.getInt('mushafFontSize')!.toDouble();
  } catch (_) {
    AppStrings.arabicFontSized = 28.0;
    AppStrings.mushafFontSized = 40.0;
  }
  
}
 

//! Arabic Numbers

class _ArabicNumbers {
  static String convert(Object value) {
    assert(
      value is int || value is String,
      "The value object must be of type 'int' or 'String'.",
    );

    if (value is int) {
      return _toArabicNumbers(value.toString());
    } else {
      return _toArabicNumbers(value as String);
    }
  }

  static String _toArabicNumbers(String value) {
    return value
        .replaceAll('0', '٠')
        .replaceAll('1', '١')
        .replaceAll('2', '٢')
        .replaceAll('3', '٣')
        .replaceAll('4', '٤')
        .replaceAll('5', '٥')
        .replaceAll('6', '٦')
        .replaceAll('7', '٧')
        .replaceAll('8', '٨')
        .replaceAll('9', '٩');
  }
}

extension IntExtensions on int {
  /// Converts English numbers to the Arabic numbers format
  ///
  ///
  /// Example:
  /// ```dart
  /// final arabicNumbers = 0123456789.toArabicNumbers;
  /// // result: ٠١٢٣٤٥٦٧٨٩
  /// ```
  String get toArabicNumbers {
    return _ArabicNumbers.convert(this);
  }
}

extension StringExtensions on String {
  /// Converts English numbers to the Arabic numbers format
  ///
  ///
  /// Example:
  /// ```dart
  /// final arabicNumbers = '0123456789'.toArabicNumbers;
  /// // result: ٠١٢٣٤٥٦٧٨٩
  /// ```
  String get toArabicNumbers {
    return _ArabicNumbers.convert(this);
  }
}
