import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../prayer/data/city_repository.dart';
import '../data/heading_service.dart';
import '../data/qibla_service.dart';
import 'qibla_state.dart';

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit({
    required CityRepository city,
    required QiblaService qibla,
    HeadingService? heading,
  })  : _city = city,
        _qibla = qibla,
        _headingService = heading,
        super(const QiblaState.ready()) {
    unawaited(reload());
    _bindHeading();
  }

  final CityRepository _city;
  final QiblaService _qibla;
  final HeadingService? _headingService;

  StreamSubscription<double>? _headingSub;

  Future<void> reload() async {
    try {
      final selected = await _city.selectedCity();
      if (isClosed) return;
      final bearing =
          selected == null ? null : _qibla.bearingDeg(selected.coordinates);
      emit(QiblaState.ready(
        city: selected,
        bearing: bearing,
        heading: state.heading,
        compassUnavailable: state.compassUnavailable,
      ));
    } on Object catch (error, stackTrace) {
      // The initial state is already a usable ready(): a failed reload keeps
      // the compass on-screen instead of raising an unhandled async error.
      dev.log('qibla reload failed',
          name: 'quran_yahdi/qibla', error: error, stackTrace: stackTrace);
    }
  }

  void _bindHeading() {
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
    );
  }

  void _markCompassUnavailable() {
    if (isClosed) return;
    final state = this.state;
    emit(QiblaState.ready(
      city: state.city,
      bearing: state.bearing,
      heading: null,
      compassUnavailable: true,
    ));
  }

  void _onHeading(double degrees) {
    if (isClosed) return;
    final state = this.state;
    emit(QiblaState.ready(
      city: state.city,
      bearing: state.bearing,
      heading: degrees,
      compassUnavailable: false,
    ));
  }

  @override
  Future<void> close() async {
    await _headingSub?.cancel();
    _headingSub = null;
    return super.close();
  }
}
