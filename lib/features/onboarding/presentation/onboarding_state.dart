import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

/// The setup flow's state: what is already done and whether it was dismissed.
@freezed
sealed class OnboardingState with _$OnboardingState {
  /// The first read is in flight.
  const factory OnboardingState.loading() = OnboardingLoading;

  /// The steps are known.
  ///
  /// [completed] is true once the flag is stored, so the screen can pop and
  /// Home stops advertising the flow.
  const factory OnboardingState.ready({
    @Default(false) bool citySelected,
    @Default(null) String? cityName,
    @Default(false) bool remindersGranted,
    @Default(false) bool completed,
  }) = OnboardingReady;
}
