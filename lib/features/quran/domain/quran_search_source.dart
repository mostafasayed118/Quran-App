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

/// Splits a raw query into normalized search tokens.
///
/// Uses the same normalization as the index build, then drops punctuation so
/// a pasted ayah with commas or full stops still matches.
List<String> quranSearchTokens(String query) {
  final normalized = normalizeArabic(query).toLowerCase();
  final words = normalized.replaceAll(_nonSearchChars, ' ').trim();
  if (words.isEmpty) return const [];
  return [for (final token in words.split(RegExp(r'\s+'))) token];
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
