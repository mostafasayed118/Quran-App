import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';

void main() {
  test('a fixed tick rotates by the negative heading', () {
    expect(dialTickAngleDeg(0, 90), 270);
    expect(dialTickAngleDeg(90, 90), 0);
    expect(dialTickAngleDeg(180, 45), 135);
    expect(dialTickAngleDeg(270, 360), 270);
  });
}
