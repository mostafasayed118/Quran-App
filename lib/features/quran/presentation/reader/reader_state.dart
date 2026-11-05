import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/verse.dart';
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
    required List<Verse> ayahs,
    @Default(ReaderMode.verses) ReaderMode mode,
    @Default(<int>{}) Set<int> bookmarkedAyahIds,
    @Default(true) bool showBasmala,
    @Default(1.0) double fontScale,
  }) = ReaderReady;

  /// The load failed. [emptySurahId] is set when the surah itself has no
  /// readable ayahs — a distinct, user-meaningful reason the screen shows
  /// instead of the generic error pane.
  const factory ReaderState.failed({
    @Default(null) int? emptySurahId,
  }) = ReaderFailed;
}

/// The mushaf pages, derived from [ReaderReady.ayahs] on demand.
///
/// They were a second stored field until 2026-11-05; a `copyWith(ayahs:)`
/// could then leave the page list stale. Deriving them makes divergence
/// impossible, and the surah-sized grouping is cheap enough for the build.
extension ReaderReadyPages on ReaderReady {
  /// The ayahs grouped by their mushaf page, in page order.
  List<MushafPageBlock> get mushafPages => groupVersesByPage(ayahs);
}

/// Legacy alias for the pre-rename concrete class (frozen suite).
typedef ReaderError = ReaderFailed;

/// Legacy accessor: the failed state carries no diagnostic any more (the
/// localized error pane is the UI contract), but the frozen suite still
/// reads `message`.
extension ReaderFailedMessage on ReaderFailed {
  String get message => 'failed';
}
