import 'package:freezed_annotation/freezed_annotation.dart';

import '../../prayer/data/city_repository.dart';

part 'qibla_state.freezed.dart';

@freezed
sealed class QiblaState with _$QiblaState {
  const factory QiblaState.ready({
    @Default(null) City? city,
    @Default(null) double? bearing,
    @Default(null) double? heading,
  }) = QiblaReady;
}
