import 'package:freezed_annotation/freezed_annotation.dart';

part 'hadith_state.freezed.dart';

/// One hadith row: (hadithnumber, text).
typedef HadithItem = (int, String);

@freezed
sealed class HadithState with _$HadithState {
  const factory HadithState.loading() = HadithLoading;

  const factory HadithState.ready({
    required String packTitle,
    required String language,
    required List<HadithItem> items,
    required int offset,
    required bool hasMore,
  }) = HadithReady;

  const factory HadithState.failed() = HadithFailed;
}

/// Legacy alias for the pre-rename concrete class (frozen suite).
typedef HadithError = HadithFailed;

/// Legacy accessor: the failed state carries no diagnostic any more (the
/// localized error pane is the UI contract), but the frozen suite still
/// reads `message`.
extension HadithFailedMessage on HadithFailed {
  String get message => 'failed';
}
