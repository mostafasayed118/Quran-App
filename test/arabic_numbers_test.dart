import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/arabic_numbers.dart';

void main() {
  test('converts western digits to Arabic-Indic', () {
    expect(0.toArabicIndic, '٠');
    expect(7.toArabicIndic, '٧');
    expect(12.toArabicIndic, '١٢');
    expect(6236.toArabicIndic, '٦٢٣٦');
  });
}
