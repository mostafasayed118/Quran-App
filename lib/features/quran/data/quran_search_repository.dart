import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/quran_search_source.dart';

/// Reads Quran search results from the derived `ayah_search` index.
class QuranSearchRepository implements QuranSearchSource {
  QuranSearchRepository(this._db);

  final AppDatabase _db;

  /// Paging re-runs the same query with the same tokens; the total is a
  /// property of the (static) search index, so it is computed once per query.
  final SearchTotalCache _totals = SearchTotalCache();

  @override
  Future<QuranSearchPage> search(
    String query, {
    int? afterAyahId,
    int limit = kQuranSearchPageSize,
  }) async {
    final tokens = quranSearchTokens(query);
    if (tokens.isEmpty || !quranSearchQueryUsable(query)) {
      return const QuranSearchPage(hits: [], total: 0, hasMore: false);
    }
    // FTS5 trigram + MATCH preserves the legacy substring/contains semantics
    // (LIKE '%token%') while using the FTS index. Tokens are normalized
    // Arabic/digits ([quranSearchTokens]) so they are safe FTS terms; implicit
    // space = AND across tokens.
    final match = _ftsMatch(tokens);
    final total = await _totalFor(tokens, match);
    final rows = await _rows(match, afterAyahId, limit + 1);
    final hasMore = rows.length > limit;
    final hits = [
      for (final row in hasMore ? rows.sublist(0, limit) : rows)
        QuranSearchHit(
          ayahId: row.read<int>('ayah_id'),
          surahId: row.read<int>('surah_id'),
          numberInSurah: row.read<int>('number_in_surah'),
          surahNameAr: row.read<String>('name_ar'),
          textImlaei: row.read<String>('text_imlaei'),
        ),
    ];
    return QuranSearchPage(hits: hits, total: total, hasMore: hasMore);
  }

  /// Builds an FTS5 MATCH expression: every token must appear (AND).
  ///
  /// Each token is quoted so FTS5 treats it as a literal term; tokens are
  /// already stripped to safe search characters by [quranSearchTokens].
  static String _ftsMatch(List<String> tokens) =>
      tokens.map((t) => '"${t.replaceAll('"', '""')}"').join(' ');

  Future<int> _totalFor(List<String> tokens, String match) async {
    final signature = tokens.join(' ');
    final cached = _totals.lookup(signature);
    if (cached != null) return cached;
    final total = await _count(match);
    _totals.store(signature, total);
    return total;
  }

  Future<int> _count(String match) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM ayah_search WHERE ayah_search MATCH ?',
      variables: [Variable<String>(match)],
    ).getSingle();
    return row.read<int>('c');
  }

  Future<List<QueryRow>> _rows(
    String match,
    int? afterAyahId,
    int fetch,
  ) async {
    final sql = StringBuffer('SELECT s.rowid AS ayah_id, a.surah_id, '
        'a.number_in_surah, u.name_ar, a.text_imlaei '
        'FROM ayah_search s '
        'JOIN ayahs a ON a.id = s.rowid '
        'JOIN surahs u ON u.id = a.surah_id '
        'WHERE ayah_search MATCH ?');
    final variables = <Variable<Object>>[Variable<String>(match)];
    if (afterAyahId != null) {
      sql.write(' AND s.rowid > ?');
      variables.add(Variable<int>(afterAyahId));
    }
    sql.write(' ORDER BY s.rowid LIMIT ?');
    variables.add(Variable<int>(fetch));
    return _db.customSelect(sql.toString(), variables: variables).get();
  }
}

/// One-entry memo for the search `COUNT(*)` scan.
///
/// The signature is the normalized token list: the same tokens produce the
/// same `WHERE` clause, and the `ayah_search` index is static content (built
/// with the shipped DB), so a page-2 request cannot see a different total.
class SearchTotalCache {
  ({String signature, int total})? _entry;

  /// The remembered total for [signature], or null when it was not scanned.
  int? lookup(String signature) =>
      _entry?.signature == signature ? _entry!.total : null;

  /// Remembers [total] as the answer for [signature].
  void store(String signature, int total) {
    _entry = (signature: signature, total: total);
  }
}
