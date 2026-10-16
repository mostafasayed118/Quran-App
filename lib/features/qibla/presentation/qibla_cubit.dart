import 'dart:async';

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
    final selected = await _city.selectedCity();
    if (isClosed) return;
    final bearing =
        selected == null ? null : _qibla.bearingDeg(selected.coordinates);
    emit(QiblaState.ready(
      city: selected,
      bearing: bearing,
      heading: state.heading,
    ));
  }

  void _bindHeading() {
    final stream = _headingService?.headingStream();
    if (stream == null) return;
    _headingSub = stream.listen(
      _onHeading,
      onError: (Object _) {},
    );
  }

  void _onHeading(double degrees) {
    if (isClosed) return;
    final state = this.state;
    emit(QiblaState.ready(
      city: state.city,
      bearing: state.bearing,
      heading: degrees,
    ));
  }

  @override
  Future<void> close() async {
    await _headingSub?.cancel();
    _headingSub = null;
    return super.close();
  }
}
