import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/city_repository.dart';
import '../../data/location_service.dart';
import 'city_picker_state.dart';

/// The city picker: the search results and the selected city.
class CityPickerCubit extends Cubit<CityPickerState> {
  /// Creates the cubit and runs the first (empty) search.
  ///
  /// [location] is optional — without it the "locate me" affordance is not
  /// offered.
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

  /// Searches the city catalog for [query] and emits the results.
  ///
  /// The first call also loads the persisted selection; a failure emits the
  /// failed state (the error is logged, never raised as an unhandled async
  /// error).
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

  /// Stores [city] as the selected city.
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
