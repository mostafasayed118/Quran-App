import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/city_repository.dart';

part 'city_picker_state.freezed.dart';

@freezed
sealed class CityPickerState with _$CityPickerState {
  const factory CityPickerState.loading() = CityPickerLoading;

  /// The city load threw: show the localized error pane; the search field
  /// stays usable so retyping re-runs the search.
  const factory CityPickerState.failed() = CityPickerFailed;

  const factory CityPickerState.ready({
    @Default('') String query,
    @Default(<City>[]) List<City> results,
    @Default(false) bool locating,
    @Default(null) String? selectedCityId,
  }) = CityPickerReady;
}
