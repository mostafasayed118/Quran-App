import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/city_repository.dart';
import 'city_picker_state.dart';

class CityPickerCubit extends Cubit<CityPickerState> {
  CityPickerCubit({required CityRepository cityRepo})
      : _cityRepo = cityRepo,
        super(const CityPickerState.loading()) {
    unawaited(search(''));
  }

  final CityRepository _cityRepo;

  Future<void> search(String query) async {
    final results = await _cityRepo.search(query);
    if (isClosed) return;
    emit(CityPickerState.ready(query: query, results: results));
  }

  Future<void> persist(City city) => _cityRepo.select(city);
}
