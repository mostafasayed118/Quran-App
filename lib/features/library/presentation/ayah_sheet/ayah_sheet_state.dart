import 'package:freezed_annotation/freezed_annotation.dart';

part 'ayah_sheet_state.freezed.dart';

/// One resolved text for the current ayah: from which pack, and its text.
typedef AyahSheetEntry = ({String title, String text});

@freezed
sealed class AyahSheetState with _$AyahSheetState {
  const factory AyahSheetState.loading() = AyahSheetLoading;

  const factory AyahSheetState.ready({
    required List<AyahSheetEntry> tafsirEntries,
    required List<AyahSheetEntry> translationEntries,
  }) = AyahSheetReady;

  const factory AyahSheetState.failed() = AyahSheetFailed;
}

/// Legacy alias for the pre-rename concrete class (frozen suite).
typedef AyahSheetError = AyahSheetFailed;

/// Legacy accessor: the failed state carries no diagnostic any more (the
/// localized error pane is the UI contract), but the frozen suite still
/// reads `message`.
extension AyahSheetFailedMessage on AyahSheetFailed {
  String get message => 'failed';
}
