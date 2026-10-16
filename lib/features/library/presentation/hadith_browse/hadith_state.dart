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
}
