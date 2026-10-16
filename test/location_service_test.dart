import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/prayer/data/location_service.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';

void main() {
  group('LocationService', () {
    test('returns the coordinates provided by the injected resolver', () async {
      final service = LocationService(
        resolver: () async => const CityCoordinates(30.05, 31.22),
      );
      final coords = await service.currentPosition();
      expect(coords, isNotNull);
      expect(coords!.latitude, 30.05);
      expect(coords.longitude, 31.22);
    });

    test('a null resolver result (denied/disabled) maps to null', () async {
      final service = LocationService(resolver: () async => null);
      expect(await service.currentPosition(), isNull);
    });

    test('a throwing resolver never throws upward — maps to null', () async {
      final service = LocationService(
        resolver: () async => throw StateError('permission denied'),
      );
      expect(await service.currentPosition(), isNull);
    });
  });
}
