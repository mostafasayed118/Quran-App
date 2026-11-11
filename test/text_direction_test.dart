import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/utils/text_direction.dart';

void main() {
  test('Arabic script is detected', () {
    expect(isArabicText('بسم الله الرحمن الرحيم'), isTrue);
    expect(isArabicText('سورة البقرة'), isTrue);
  });

  test('Latin text is not', () {
    expect(isArabicText('In the name of Allah'), isFalse);
    expect(isArabicText(''), isFalse);
    expect(isArabicText('1234'), isFalse);
  });

  test('mixed text counts as Arabic', () {
    expect(isArabicText('Allah — الله'), isTrue);
  });
}
