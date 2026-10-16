import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/city_repository.dart';

part 'city_picker_state.freezed.dart';

@freezed
sealed class CityPickerState with _$CityPickerState {
  const factory CityPickerState.loading() = CityPickerLoading;

  const factory CityPickerState.ready({
    @Default('') String query,
    @Default(<City>[]) List<City> results,
    @Default(false) bool locating,
  }) = CityPickerReady;
}
