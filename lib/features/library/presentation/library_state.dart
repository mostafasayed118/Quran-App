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

  const factory LibraryState.failed() = LibraryFailed;
}

/// Legacy accessor: the failed state carries no diagnostic any more (the
/// localized error pane is the UI contract), but the frozen suite still
/// reads `message`.
extension LibraryFailedMessage on LibraryFailed {
  String get message => 'failed';
}
