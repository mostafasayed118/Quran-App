import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/khatma_progress.dart';
import '../domain/tracker_day.dart';

part 'tracker_state.freezed.dart';

@freezed
sealed class TrackerState with _$TrackerState {
  const factory TrackerState.loading() = TrackerLoading;

  const factory TrackerState.failed() = TrackerFailed;

  const factory TrackerState.ready({
    required TrackerDay today,
    @Default(0) int streakDays,
    @Default(<bool>[]) List<bool> last7,
    @Default(false) bool khatmaAvailable,
    @Default(null) KhatmaProgress? khatma,
    @Default(false) bool actionFailed,
  }) = TrackerReady;
}
