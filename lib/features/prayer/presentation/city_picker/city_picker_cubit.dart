import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/city_repository.dart';
import '../../data/location_service.dart';
import 'city_picker_state.dart';

class CityPickerCubit extends Cubit<CityPickerState> {
  CityPickerCubit({required CityRepository cityRepo, LocationService? location})
      : _cityRepo = cityRepo,
        _location = location,
        super(const CityPickerState.loading()) {
    unawaited(search(''));
  }

  final CityRepository _cityRepo;
  final LocationService? _location;

  Future<void> search(String query) async {
    final results = await _cityRepo.search(query);
    if (isClosed) return;
    emit(CityPickerState.ready(query: query, results: results));
  }

  Future<void> persist(City city) => _cityRepo.select(city);

  /// Resolves the device position to the nearest bundled city, persists it and
  /// returns it — or null when unavailable (denied/disabled/offline), in which
  /// case the caller keeps the manual picker and shows a neutral hint.
  Future<City?> locateNearest() async {
    final location = _location;
    if (location == null || isClosed) return null;
    _emitLocating(true);
    final coords = await location.currentPosition();
    if (isClosed) return null;
    if (coords == null) {
      _emitLocating(false);
      return null;
    }
    final city = await _cityRepo.nearestTo(coords.latitude, coords.longitude);
    if (isClosed) return null;
    await _cityRepo.select(city);
    if (isClosed) return null;
    _emitLocating(false);
    return city;
  }

  void _emitLocating(bool locating) {
    final state = this.state;
    if (state is CityPickerReady) {
      emit(CityPickerState.ready(
        query: state.query,
        results: state.results,
        locating: locating,
      ));
    }
  }
}
