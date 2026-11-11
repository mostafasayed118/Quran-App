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

/// Screen angle of a fixed dial tick after the device heading.
///
/// The cardinal words and the qibla marker already rotate with [headingDeg];
/// the tick ring is the same frame, so it must rotate by the same term.
double dialTickAngleDeg(double tickDeg, double headingDeg) =>
    (tickDeg - headingDeg) % 360.0;

/// EMA weight for one magnetometer sample. sensors_plus' default interval is
/// 200 ms (5 Hz), so 0.3 is a ~0.5 s time constant.
const double kHeadingSmoothingAlpha = 0.3;

/// A step this large is a real turn, not jitter: pass it straight through so
/// a 30° turn does not take two seconds to arrive on the dial.
const double kHeadingSnapDeg = 10.0;

/// Signed shortest turn from [from] to [to], in (-180, 180].
double shortestAngleDeltaDeg(double to, double from) {
  final delta = (to - from) % 360.0;
  return delta > 180.0 ? delta - 360.0 : delta;
}

/// One low-pass step on the compass circle.
///
/// [previous] is the last smoothed heading; the caller seeds the first sample
/// by assigning it directly, so this function never sees a null seed.
double smoothHeadingDeg(double previous, double sample) {
  final delta = shortestAngleDeltaDeg(sample, previous);
  if (delta.abs() >= kHeadingSnapDeg) return sample % 360.0;
  return (previous + kHeadingSmoothingAlpha * delta + 360.0) % 360.0;
}

/// Injectable heading source for the qibla dial.
///
/// [headingStream] returns null when sensors are unavailable on the device
/// (e.g. no magnetometer) or the platform channel cannot be created; the
/// qibla screen then stays in its static mode.
class HeadingService {
  HeadingService({HeadingStreamFactory? streamFactory})
      : _streamFactory = streamFactory ?? _deviceHeadingStream;

  final HeadingStreamFactory _streamFactory;

  /// Device heading in degrees; null when the device has no magnetometer.
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
