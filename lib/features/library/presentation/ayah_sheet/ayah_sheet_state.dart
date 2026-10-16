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
}
