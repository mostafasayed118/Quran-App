import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

typedef HeadingStreamFactory = Stream<double>? Function();

/// Converts a raw magnetometer sample (device axes, microtesla) into a
/// compass heading in degrees clockwise from north.
double headingFromMagnetometer(double x, double y) {
  final degrees = math.atan2(-x, y) * 180.0 / math.pi;
  return (degrees + 360.0) % 360.0;
}

/// Angle (degrees) the qibla arrow must rotate to point at the qibla given a
/// live device heading; static mode passes heading = 0.
double dialAngleDeg(double bearingDeg, double headingDeg) =>
    (bearingDeg - headingDeg) % 360.0;

/// Injectable heading source for the qibla dial.
///
/// [headingStream] returns null when sensors are unavailable on the device
/// (e.g. no magnetometer) or the platform channel cannot be created; the
/// qibla screen then stays in its static mode.
class HeadingService {
  HeadingService({HeadingStreamFactory? streamFactory})
      : _streamFactory = streamFactory ?? _deviceHeadingStream;

  final HeadingStreamFactory _streamFactory;

  Stream<double>? headingStream() {
    try {
      return _streamFactory();
    } on Object {
      return null;
    }
  }

  static Stream<double>? _deviceHeadingStream() => magnetometerEventStream()
      .map((event) => headingFromMagnetometer(event.x, event.y));
}
