import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/city.dart';

import '../data/heading_service.dart';
import '../data/qibla_service.dart';
import 'qibla_state.dart';

/// The qibla screen: the bearing to the selected city and the live heading.
class QiblaCubit extends Cubit<QiblaState> {
  /// Creates the cubit, loads the bearing and binds the heading stream.
  ///
  /// [heading] is optional — without it the device is treated as having no
  /// magnetometer and the dial stays static.
  QiblaCubit({
    required CitySource city,
    required QiblaService qibla,
    HeadingService? heading,
  })  : _city = city,
        _qibla = qibla,
        _headingService = heading,
        super(const QiblaState.loading()) {
    unawaited(reload());
    _bindHeading();
  }

  final CitySource _city;
  final QiblaService _qibla;
  final HeadingService? _headingService;

  StreamSubscription<double>? _headingSub;
  double? _heading;
  bool _compassUnavailable = false;

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
      ));
    } on Object catch (error, stackTrace) {
      dev.log('qibla reload failed',
          name: 'quran_yahdi/qibla', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const QiblaState.failed());
    }
  }

  /// Stops the sensor stream while the app is backgrounded. The last heading
  /// stays displayed (no emission).
  Future<void> pause() async {
    final sub = _headingSub;
    // Detach synchronously: a resume arriving while the cancel is still in
    // flight must be able to bind a fresh stream, and the late continuation
    // must not clobber that new subscription.
    _headingSub = null;
    await sub?.cancel();
  }

  /// Re-acquires the heading stream after a [pause] (the service hands out a
  /// fresh stream per call).
  void resume() => _bindHeading();

  void _bindHeading() {
    if (_headingSub != null) return;
    final stream = _headingService?.headingStream();
    if (stream == null) {
      _markCompassUnavailable();
      return;
    }
    _headingSub = stream.listen(
      _onHeading,
      onError: (Object error, StackTrace stackTrace) {
        dev.log(
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
  }

  void _markCompassUnavailable() {
    _heading = null;
    _compassUnavailable = true;
    if (isClosed) return;
    final state = this.state;
    if (state is! QiblaReady) return;
    emit(QiblaState.ready(
      city: state.city,
      bearing: state.bearing,
      heading: null,
      compassUnavailable: true,
    ));
  }

  void _onHeading(double degrees) {
    _heading = degrees;
    _compassUnavailable = false;
    if (isClosed) return;
    final state = this.state;
    if (state is! QiblaReady) return;
    emit(QiblaState.ready(
      city: state.city,
      bearing: state.bearing,
      heading: degrees,
      compassUnavailable: false,
    ));
  }

  /// Cancels the heading subscription before closing the cubit.
  @override
  Future<void> close() async {
    await _headingSub?.cancel();
    _headingSub = null;
    return super.close();
  }
}
