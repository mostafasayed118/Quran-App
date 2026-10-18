import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/prayer_log_repository.dart';

part 'tracker_state.freezed.dart';

@freezed
sealed class TrackerState with _$TrackerState {
  const factory TrackerState.loading() = TrackerLoading;

  const factory TrackerState.failed() = TrackerFailed;

  const factory TrackerState.ready({
    required TrackerDay today,
    @Default(0) int streakDays,
    @Default(<bool>[]) List<bool> last7,
  }) = TrackerReady;
}
