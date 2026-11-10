import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../data/compass_calibration.dart';
import '../data/heading_service.dart';
import '../data/qibla_service.dart';
import 'qibla_state.dart';

/// The qibla screen: the bearing to the selected city and the live heading.
class QiblaCubit extends Cubit<QiblaState> {
  /// Creates the cubit without doing any work; call [start] to load.
  ///
  /// [heading] is optional — without it the device is treated as having no
  /// magnetometer and the dial stays static.
  QiblaCubit({
    required CitySource city,
    required QiblaService qibla,
    HeadingService? heading,
    CompassCalibration? calibration,
  })  : _city = city,
        _qibla = qibla,
        _headingService = heading,
        _calibration = calibration,
        super(const QiblaState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() async {
    final loaded = reload();
    _bindHeading();
    await loaded;
  }

  final CitySource _city;
  final QiblaService _qibla;
  final HeadingService? _headingService;
  final CompassCalibration? _calibration;

  StreamSubscription<double>? _headingSub;
  StreamSubscription<bool>? _calibrationSub;
  double? _heading;
  double? _smoothedHeading;
  bool _compassUnavailable = false;
  bool _calibrationNeeded = false;

  /// Loads the selected city and its bearing and emits the ready state.
  ///
  /// A failure emits [QiblaState.failed] — the error is logged, never
  /// raised as an unhandled async error.
  Future<void> reload() async {
    try {
      final selected = await _city.selectedCity();
      if (isClosed) return;
      final bearing =
          selected == null ? null : _qibla.bearingDeg(selected.coordinates);
      emit(QiblaState.ready(
        city: selected,
        bearing: bearing,
        heading: _heading,
        compassUnavailable: _compassUnavailable,
        calibrationNeeded: _calibrationNeeded,
      ));
    } on Object catch (error, stackTrace) {
      appLog('qibla reload failed',
          name: 'quran_yahdi/qibla', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const QiblaState.failed());
    }
  }

  /// Stops the sensor stream while the app is backgrounded. The last heading
  /// stays displayed (no emission).
  Future<void> pause() async {
    final headingSub = _headingSub;
    final calibrationSub = _calibrationSub;
    // Detach synchronously: a resume arriving while the cancel is still in
    // flight must be able to bind a fresh stream, and the late continuation
    // must not clobber that new subscription.
    _headingSub = null;
    _calibrationSub = null;
    await headingSub?.cancel();
    await calibrationSub?.cancel();
  }

  /// Re-acquires the heading stream after a [pause] (the service hands out a
  /// fresh stream per call).
  void resume() => _bindHeading();

  void _bindHeading() {
    if (_headingSub != null) return;
    _smoothedHeading = null;
    final stream = _headingService?.headingStream();
    if (stream == null) {
      _markCompassUnavailable();
      return;
    }
    _headingSub = stream.listen(
      _onHeading,
      onError: (Object error, StackTrace stackTrace) {
        appLog(
          'heading stream error',
          name: 'quran_yahdi/qibla',
          error: error,
          stackTrace: stackTrace,
        );
        _markCompassUnavailable();
      },
      onDone: () {
        _headingSub = null;
        _markCompassUnavailable();
      },
    );
    _bindCalibration();
  }

  void _bindCalibration() {
    if (_calibrationSub != null) return;
    final stream = _calibration?.needsCalibrationStream(
      initialNeeded: _calibrationNeeded,
    );
    if (stream == null) return;
    _calibrationSub = stream.listen(
      _onCalibration,
      onError: (Object error, StackTrace stackTrace) {
        appLog(
          'calibration stream error',
          name: 'quran_yahdi/qibla',
          error: error,
          stackTrace: stackTrace,
        );
        _onCalibration(false);
      },
    );
  }

  void _markCompassUnavailable() {
    _heading = null;
    _smoothedHeading = null;
    _compassUnavailable = true;
    _calibrationNeeded = false;
    if (isClosed) return;
    final state = this.state;
    if (state is! QiblaReady) return;
    emit(QiblaState.ready(
      city: state.city,
      bearing: state.bearing,
      heading: null,
      compassUnavailable: true,
      calibrationNeeded: false,
    ));
  }

  void _onHeading(double degrees) {
    final previous = _smoothedHeading;
    final smoothed =
        previous == null ? degrees : smoothHeadingDeg(previous, degrees);
    _smoothedHeading = smoothed;
    _heading = smoothed;
    _compassUnavailable = false;
    if (isClosed) return;
    final state = this.state;
    if (state is! QiblaReady) return;
    emit(QiblaState.ready(
      city: state.city,
      bearing: state.bearing,
      heading: smoothed,
      compassUnavailable: false,
      calibrationNeeded: _calibrationNeeded,
    ));
  }

  void _onCalibration(bool needed) {
    if (isClosed || _calibrationNeeded == needed) return;
    _calibrationNeeded = needed;
    final state = this.state;
    if (state is! QiblaReady) return;
    emit(QiblaState.ready(
      city: state.city,
      bearing: state.bearing,
      heading: state.heading,
      compassUnavailable: state.compassUnavailable,
      calibrationNeeded: needed,
    ));
  }

  /// Cancels the heading and calibration subscriptions before closing.
  @override
  Future<void> close() async {
    await _headingSub?.cancel();
    await _calibrationSub?.cancel();
    _headingSub = null;
    _calibrationSub = null;
    return super.close();
  }
}
