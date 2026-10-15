import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../prayer/data/city_repository.dart';
import '../data/qibla_service.dart';
import 'qibla_state.dart';

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit({
    required CityRepository city,
    required QiblaService qibla,
  })  : _city = city,
        _qibla = qibla,
        super(const QiblaState.ready()) {
    unawaited(reload());
  }

  final CityRepository _city;
  final QiblaService _qibla;

  Future<void> reload() async {
    final selected = await _city.selectedCity();
    if (isClosed) return;
    final bearing =
        selected == null ? null : _qibla.bearingDeg(selected.coordinates);
    emit(QiblaState.ready(city: selected, bearing: bearing));
  }
}
