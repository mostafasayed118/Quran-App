import 'dart:async';
import 'dart:developer' as dev;

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

  String? _selectedCityId;
  bool _selectedLoaded = false;

  Future<void> search(String query) async {
    try {
      final results = await _cityRepo.search(query);
      if (!_selectedLoaded) {
        _selectedCityId = (await _cityRepo.selectedCity())?.id;
        _selectedLoaded = true;
      }
      if (isClosed) return;
      emit(CityPickerState.ready(
        query: query,
        results: results,
        selectedCityId: _selectedCityId,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('city search failed',
          name: 'quran_yahdi/city_picker',
          error: error,
          stackTrace: stackTrace);
      if (isClosed) return;
      emit(const CityPickerState.failed());
    }
  }

  Future<void> persist(City city) async {
    await _cityRepo.select(city);
    _selectedCityId = city.id;
    _selectedLoaded = true;
  }

  /// Resolves the device position to the nearest bundled city, persists it and
  /// returns it — or null when unavailable (denied/disabled/offline), in which
  /// case the caller keeps the manual picker and shows a neutral hint.
  Future<City?> locateNearest() async {
    final location = _location;
    if (location == null || isClosed) return null;
    _emitLocating(true);
    try {
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
    } on Object catch (error, stackTrace) {
      dev.log('nearest-city resolve failed',
          name: 'quran_yahdi/city_picker',
          error: error,
          stackTrace: stackTrace);
      if (!isClosed) _emitLocating(false);
      return null;
    }
  }

  void _emitLocating(bool locating) {
    final state = this.state;
    if (state is CityPickerReady) {
      emit(CityPickerState.ready(
        query: state.query,
        results: state.results,
        locating: locating,
        selectedCityId: state.selectedCityId,
      ));
    }
  }

  /// Opens the device location settings after a failed locate (best-effort).
  Future<void> openLocationSettings() async {
    await _location?.openLocationSettings();
  }
}
