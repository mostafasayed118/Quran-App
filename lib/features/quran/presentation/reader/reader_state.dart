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

    /// The ayah the reader is on now. It survives a mode switch and is the
    /// anchor both modes start from; [initialAyah] is only the route request.
    @Default(0) int currentAyahId,
    @Default(ReaderMode.verses) ReaderMode mode,
    @Default(<int>{}) Set<int> bookmarkedAyahIds,
    @Default(true) bool showBasmala,
    @Default(1.0) double fontScale,
    @Default(2.2) double lineHeight,
  }) = ReaderReady;

  /// The load failed. [emptySurahId] is set when the surah itself has no
  /// readable ayahs — a distinct, user-meaningful reason the screen shows
  /// instead of the generic error pane.
  const factory ReaderState.failed({
    @Default(null) int? emptySurahId,
  }) = ReaderFailed;
}

/// The mushaf pages, derived from [ReaderReady.ayahs] and memoized per
/// [ReaderReady] instance.
///
/// They were a second stored field until 2026-11-05; a `copyWith(ayahs:)`
/// could then leave the page list stale. Deriving them avoids divergence, and
/// the [Expando] cache prevents recomputing the surah-sized grouping on every
/// rebuild/page-change access (the same ready instance is read many times).
final Expando<List<MushafPageBlock>> _readerMushafPagesCache =
    Expando<List<MushafPageBlock>>('readerMushafPages');

extension ReaderReadyPages on ReaderReady {
  /// The ayahs grouped by their mushaf page, in page order.
  List<MushafPageBlock> get mushafPages =>
      _readerMushafPagesCache[this] ??= groupVersesByPage(ayahs);
}

/// Legacy alias for the pre-rename concrete class (frozen suite).
typedef ReaderError = ReaderFailed;

/// Legacy test-only accessor: the failed state carries no diagnostic any more
/// (the localized error pane is the UI contract). Frozen Class A tests may still
/// read `message`; removing this shim requires migrating those tests under the
/// frozen-test policy (owner ruling). Do not use in production/UI code.
extension ReaderFailedMessage on ReaderFailed {
  String get message => 'failed';
}
