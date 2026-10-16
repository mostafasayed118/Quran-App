import 'package:geolocator/geolocator.dart';

import 'prayer_time_service.dart';

typedef PositionResolver = Future<CityCoordinates?> Function();

/// Thin injectable wrapper around the device location stack.
///
/// [currentPosition] never throws upward: denial, disabled services, timeouts
/// and platform errors all collapse to `null`, letting callers fall back to
/// manual selection.
class LocationService {
  LocationService({PositionResolver? resolver})
      : _resolver = resolver ?? resolveFromDevice;

  final PositionResolver _resolver;

  Future<CityCoordinates?> currentPosition() async {
    try {
      return await _resolver();
    } on Object {
      return null;
    }
  }

  static Future<CityCoordinates?> resolveFromDevice() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return CityCoordinates(position.latitude, position.longitude);
  }
}
