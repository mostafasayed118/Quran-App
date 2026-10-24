import 'package:freezed_annotation/freezed_annotation.dart';

part 'hijri_state.freezed.dart';

class HijriCell {
  const HijriCell({
    required this.hDay,
    required this.gDay,
    required this.isToday,
  });

  final int hDay;
  final int gDay;
  final bool isToday;
}

@freezed
sealed class HijriState with _$HijriState {
  const factory HijriState.loading() = HijriLoading;

  /// Load failed (a service read threw): the screen shows the localized
  /// error pane instead of hanging on [HijriState.loading] forever.
  const factory HijriState.failed() = HijriFailed;

  const factory HijriState.ready({
    required int month,
    required int year,
    required String monthName,
    required int offset,
    required List<HijriCell> cells,
    required String todayHeader,
  }) = HijriReady;
}
