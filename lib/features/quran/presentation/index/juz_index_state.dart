import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/juz_summary.dart';

part 'juz_index_state.freezed.dart';

/// The juz index screen state.
@freezed
sealed class JuzIndexState with _$JuzIndexState {
  /// The first read is in flight.
  const factory JuzIndexState.loading() = JuzIndexLoading;

  /// The read failed.
  const factory JuzIndexState.failed() = JuzIndexFailed;

  /// The 30 juz starts are available.
  const factory JuzIndexState.ready(List<JuzSummary> juz) = JuzIndexReady;
}
