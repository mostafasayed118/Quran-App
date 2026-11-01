import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

/// One raw magnetometer sample in microtesla on the device axes.
class MagneticSample {
  /// Creates a sample.
  const MagneticSample(this.x, this.y, this.z);

  /// Device x axis, microtesla.
  final double x;

  /// Device y axis, microtesla.
  final double y;

  /// Device z axis, microtesla.
  final double z;
}

/// Injectable magnetic-field source; null when the device has no magnetometer.
typedef MagneticStreamFactory = Stream<MagneticSample>? Function();

/// The earth's field is roughly 25–65 µT depending on location; outside this
/// window a nearby magnet or metal is the likely cause.
const double kMinFieldMicroTesla = 20;
const double kMaxFieldMicroTesla = 70;

/// A near-vertical phone makes the 2-D heading invalid; |z|/|B| above this
/// ratio is treated as "lay the phone flatter".
const double kMaxTiltRatio = 0.90;

/// Consecutive bad samples before the hint appears (~2 s at 5 Hz).
const int kBadSamplesToRaise = 10;

/// Consecutive good samples before the hint clears (~4 s at 5 Hz).
const int kGoodSamplesToClear = 20;

/// Whether [sample] looks like a disturbed field or an invalid tilt.
bool fieldLooksDisturbed(MagneticSample sample) {
  final magnitude = math.sqrt(
    sample.x * sample.x + sample.y * sample.y + sample.z * sample.z,
  );
  if (magnitude <= 0 ||
      magnitude < kMinFieldMicroTesla ||
      magnitude > kMaxFieldMicroTesla) {
    return true;
  }
  return sample.z.abs() / magnitude > kMaxTiltRatio;
}

/// Watches the raw field and emits a debounced "needs calibration" signal.
///
/// The heading stream is a pure double and cannot distinguish a real turn from
/// a disturbed field; this second, optional listener uses the raw x/y/z that
/// [HeadingService] discards. The platform caches the sensor broadcast stream,
/// so two listeners do not register the sensor twice.
class CompassCalibration {
  /// Creates the calibration watcher over an optional [field] source.
  CompassCalibration({MagneticStreamFactory? field})
      : _field = field ?? _deviceField;

  final MagneticStreamFactory _field;

  /// Emits only when the debounced state changes; null without a sensor.
  Stream<bool>? needsCalibrationStream() {
    try {
      final raw = _field();
      if (raw == null) return null;
      return _debounced(raw);
    } on Object {
      return null;
    }
  }

  static Stream<MagneticSample>? _deviceField() =>
      magnetometerEventStream().map(
        (event) => MagneticSample(event.x, event.y, event.z),
      );

  static Stream<bool> _debounced(Stream<MagneticSample> raw) {
    late StreamController<bool> out;
    StreamSubscription<MagneticSample>? sub;
    var bad = 0;
    var good = 0;
    var needed = false;

    void onSample(MagneticSample sample) {
      if (fieldLooksDisturbed(sample)) {
        bad++;
        good = 0;
        if (!needed && bad >= kBadSamplesToRaise) {
          needed = true;
          out.add(true);
        }
      } else {
        good++;
        bad = 0;
        if (needed && good >= kGoodSamplesToClear) {
          needed = false;
          out.add(false);
        }
      }
    }

    out = StreamController<bool>(
      onListen: () {
        sub = raw.listen(
          onSample,
          onError: out.addError,
          onDone: () {
            out.close();
          },
        );
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }
}
