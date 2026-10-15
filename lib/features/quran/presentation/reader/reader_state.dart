import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/db/app_database.dart';
import 'mushaf_page_block.dart';

part 'reader_state.freezed.dart';

enum ReaderMode { verses, mushaf }

@freezed
sealed class ReaderState with _$ReaderState {
  const factory ReaderState.loading({
    required int surahId,
    required int initialAyah,
  }) = ReaderLoading;

  const factory ReaderState.ready({
    required int surahId,
    required String surahName,
    required int initialAyah,
    required List<Ayah> ayahs,
    required List<MushafPageBlock> mushafPages,
    @Default(ReaderMode.verses) ReaderMode mode,
    @Default(<int>{}) Set<int> bookmarkedAyahIds,
    @Default(true) bool showBasmala,
  }) = ReaderReady;

  const factory ReaderState.error({required String message}) = ReaderError;
}
