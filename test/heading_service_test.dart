import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/qibla/data/heading_service.dart';

void main() {
  group('headingFromMagnetometer', () {
    test('device facing north reads 0 degrees', () {
      expect(headingFromMagnetometer(0, 50), closeTo(0, 1e-9));
    });

    test('device facing east reads 90 degrees', () {
      expect(headingFromMagnetometer(-50, 0), closeTo(90, 1e-9));
    });

    test('device facing south reads 180 degrees', () {
      expect(headingFromMagnetometer(0, -50), closeTo(180, 1e-9));
    });

    test('device facing west reads 270 degrees', () {
      expect(headingFromMagnetometer(50, 0), closeTo(270, 1e-9));
    });
  });

  group('dialAngleDeg (bearing minus live heading, normalized)', () {
    test('goldens for 0/90/180/270 headings at bearing 137.2', () {
      expect(dialAngleDeg(137.2, 0), closeTo(137.2, 1e-9));
      expect(dialAngleDeg(137.2, 90), closeTo(47.2, 1e-9));
      expect(dialAngleDeg(137.2, 180), closeTo(317.2, 1e-9));
      expect(dialAngleDeg(137.2, 270), closeTo(227.2, 1e-9));
    });
  });

  group('HeadingService', () {
    test('exposes the injected stream as-is', () async {
      final service = HeadingService(streamFactory: () => Stream.value(123.4));
      final stream = service.headingStream();
      expect(stream, isNotNull);
      expect(await stream!.first, 123.4);
    });

    test('a null factory result (no sensor) maps to null', () {
      final service = HeadingService(streamFactory: () => null);
      expect(service.headingStream(), isNull);
    });

    test('a throwing factory maps to null', () {
      final service = HeadingService(
        streamFactory: () => throw StateError('no magnetometer'),
      );
      expect(service.headingStream(), isNull);
    });
  });
}
