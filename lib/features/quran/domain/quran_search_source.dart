import '../../../core/utils/arabic_search.dart';

/// One Quran search result row.
class QuranSearchHit {
  const QuranSearchHit({
    required this.ayahId,
    required this.surahId,
    required this.numberInSurah,
    required this.surahNameAr,
    required this.textImlaei,
  });

  /// Global ayah number (1..6236) — also the paging cursor.
  final int ayahId;
  final int surahId;
  final int numberInSurah;
  final String surahNameAr;
  final String textImlaei;
}

/// One page of search results plus the total match count.
class QuranSearchPage {
  const QuranSearchPage({
    required this.hits,
    required this.total,
    required this.hasMore,
  });

  final List<QuranSearchHit> hits;
  final int total;
  final bool hasMore;
}

/// The shortest usable query, in normalized characters.
const int kQuranSearchMinChars = 2;

/// Default page size for search paging.
const int kQuranSearchPageSize = 20;

/// Upper bound on query tokens (the legacy substring path binds one SQL
/// variable per token, so this must stay far below SQLite's 999 cap).
///
/// 64 keeps the AND-semantics meaningful even for a pasted ayah while leaving
/// ample headroom under 999 for the repository's own paging variables. A
/// query past 64 words is a paste/copy artefact, not a search a human types.
const int kQuranSearchMaxTokens = 64;

/// Splits a raw query into normalized search tokens, capped at
/// [kQuranSearchMaxTokens].
///
/// Uses the same normalization as the index build, then drops punctuation so
/// a pasted ayah with commas or full stops still matches. The cap is applied
/// here — before any SQL is built — so the legacy `LIKE ?` chain can never
/// exceed SQLite's host-parameter ceiling for any input.
List<String> quranSearchTokens(String query) {
  final normalized = normalizeArabic(query).toLowerCase();
  final words = normalized.replaceAll(_nonSearchChars, ' ').trim();
  if (words.isEmpty) return const [];
  final tokens = <String>[];
  for (final token in words.split(RegExp(r'\s+'))) {
    if (tokens.length >= kQuranSearchMaxTokens) break;
    tokens.add(token);
  }
  return tokens;
}

/// Whether [query] is long enough to run a search for.
bool quranSearchQueryUsable(String query) {
  final tokens = quranSearchTokens(query);
  return tokens.isNotEmpty && tokens.join().length >= kQuranSearchMinChars;
}

final RegExp _nonSearchChars = RegExp(r'[^\u0621-\u064A\u0660-\u0669a-z0-9]+');

/// Quran text search seam; the drift-backed repository is the v1 impl.
abstract class QuranSearchSource {
  /// Ayahs whose normalized text contains every query token, in mushaf order.
  ///
  /// [afterAyahId] is the keyset cursor: only ayahs after it are returned.
  Future<QuranSearchPage> search(
    String query, {
    int? afterAyahId,
    int limit = kQuranSearchPageSize,
  });
}
