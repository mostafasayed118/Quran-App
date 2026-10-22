import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/city.dart';

part 'qibla_state.freezed.dart';

@freezed
sealed class QiblaState with _$QiblaState {
  /// The first city/bearing load is in flight. Carries the same fields as
  /// [QiblaState.ready] so the union keeps one field surface.
  const factory QiblaState.loading({
    @Default(null) City? city,
    @Default(null) double? bearing,
    @Default(null) double? heading,
    @Default(false) bool compassUnavailable,
  }) = QiblaLoading;

  /// The compass is ready: the selected city, the bearing to it and — when
  /// the device has a magnetometer — the live heading.
  ///
  /// [compassUnavailable] is NOT a failure: it marks a device without a
  /// magnetometer, where the dial stays static (the screen shows the
  /// static-compass note instead of the live one).
  const factory QiblaState.ready({
    @Default(null) City? city,
    @Default(null) double? bearing,
    @Default(null) double? heading,
    @Default(false) bool compassUnavailable,
  }) = QiblaReady;

  /// The load failed (the city lookup or the compass service threw).
  ///
  /// The variant carries the same fields as [QiblaState.ready] so the union
  /// keeps exposing them (the frozen suite reads `state.city`).
  const factory QiblaState.failed({
    @Default(null) City? city,
    @Default(null) double? bearing,
    @Default(null) double? heading,
    @Default(false) bool compassUnavailable,
  }) = QiblaFailed;
}
