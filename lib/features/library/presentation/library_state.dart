import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/library_catalog.dart';

part 'library_state.freezed.dart';

@freezed
sealed class LibraryState with _$LibraryState {
  const factory LibraryState.loading() = LibraryLoading;

  const factory LibraryState.ready({
    required List<LibraryPackInfo> packs,
    @Default(<String>{}) Set<String> installed,
    /// packId -> (received bytes, expected bytes)
    @Default(<String, (int, int)>{}) Map<String, (int, int)> progress,
    @Default(<String>{}) Set<String> failed,
  }) = LibraryReady;

  const factory LibraryState.failed({required String message}) = LibraryFailed;
}
