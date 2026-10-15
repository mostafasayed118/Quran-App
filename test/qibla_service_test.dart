import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/qibla/data/qibla_service.dart';

void main() {
  const service = QiblaService();

  test('Cairo bearing lands in the 130-145 band', () {
    final d = service.bearingDeg(const CityCoordinates(30.0444, 31.2357));
    expect(d, inInclusiveRange(130, 145));
  });

  test('makkah itself returns a finite value within [0, 360)', () {
    final d = service.bearingDeg(const CityCoordinates(21.4225, 39.8262));
    expect(d.isFinite, isTrue);
    expect(d, inInclusiveRange(0, 360),
        reason:
            'degenerate self-point artifact (adhan internal Kaaba constant), measured 324.892');
  });
}
