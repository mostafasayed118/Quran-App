import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/utils/format_bytes.dart';

void main() {
  test('a whole number drops the decimal', () {
    expect(formatMegabytesValue(2), '2');
    expect(
      formatMegabytesValue(2.0),
      '2',
      reason: 'the library used to render "٢.٠ م.ب" from the raw double',
    );
  });

  test('a fractional value keeps one decimal', () {
    expect(formatMegabytesValue(2.5), '2.5');
    expect(formatMegabytesValue(12.34), '12.3');
  });
}
