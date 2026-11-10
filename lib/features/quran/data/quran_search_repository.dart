import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/quran_search_source.dart';

/// Reads Quran search results from the derived `ayah_search` index.
class QuranSearchRepository implements QuranSearchSource {
  QuranSearchRepository(this._db);

  final AppDatabase _db;

  /// The shortest token the FTS5 `trigram` tokenizer can represent.
  ///
  /// A trigram index only stores overlapping three-character sequences, so a
  /// token shorter than this matches nothing — and is dropped from the MATCH
  /// expression entirely, which silently degrades an AND across tokens into
  /// the longer tokens alone (a superset of the truth). The common Arabic
  /// particles (`لا`, `ال`, `يا`) are all two characters, so a trigram-only
  /// index silently loses them.
  static const int _ftsTrigramMinTokenLength = 3;

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
    // Every token must appear (AND) and a token matches anywhere inside the
    // ayah. That is the semantics this file has always promised, so a query
    // the trigram tokenizer cannot represent falls back to the legacy
    // substring scan instead of quietly losing the short token.
    final plan = _planFor(tokens);
    final total = await _totalFor(tokens, plan);
    final rows = await _rows(plan, afterAyahId, limit + 1);
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

  /// How one search is run against the index.
  ///
  /// FTS5's `MATCH` needs the real table name (an alias is not accepted:
  /// "no such column"), so the two shapes cannot share one FROM clause — but
  /// they do share the ayah/surah join and the ayah-id expression.
  static _SearchPlan _planFor(List<String> tokens) {
    if (tokens.every((t) => t.length >= _ftsTrigramMinTokenLength)) {
      return _SearchPlan(
        from: 'ayah_search',
        join: 'JOIN ayahs a ON a.id = ayah_search.rowid '
            'JOIN surahs u ON u.id = a.surah_id',
        where: 'ayah_search MATCH ?',
        ayahIdExpr: 'ayah_search.rowid',
        variables: [Variable<String>(_ftsMatch(tokens))],
      );
    }
    // The legacy substring scan. It cannot use the FTS index, but it is the
    // only shape that can match a token shorter than a trigram, and it is
    // bounded by the same 6,236-row corpus.
    return _SearchPlan(
      from: 'ayah_search s',
      join: 'JOIN ayahs a ON a.id = s.rowid '
          'JOIN surahs u ON u.id = a.surah_id',
      where: List.filled(tokens.length, 's.text_norm LIKE ?').join(' AND '),
      ayahIdExpr: 's.rowid',
      variables: [for (final token in tokens) Variable<String>('%$token%')],
    );
  }

  Future<int> _totalFor(List<String> tokens, _SearchPlan plan) async {
    final signature = tokens.join(' ');
    final cached = _totals.lookup(signature);
    if (cached != null) return cached;
    final total = await _count(plan);
    _totals.store(signature, total);
    return total;
  }

  Future<int> _count(_SearchPlan plan) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM ${plan.from} WHERE ${plan.where}',
          variables: plan.variables,
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<List<QueryRow>> _rows(
    _SearchPlan plan,
    int? afterAyahId,
    int fetch,
  ) async {
    final sql = StringBuffer('SELECT ${plan.ayahIdExpr} AS ayah_id, '
        'a.surah_id, a.number_in_surah, u.name_ar, a.text_imlaei '
        'FROM ${plan.from} ${plan.join} '
        'WHERE ${plan.where}');
    final variables = <Variable<Object>>[...plan.variables];
    if (afterAyahId != null) {
      sql.write(' AND ${plan.ayahIdExpr} > ?');
      variables.add(Variable<int>(afterAyahId));
    }
    sql.write(' ORDER BY ${plan.ayahIdExpr} LIMIT ?');
    variables.add(Variable<int>(fetch));
    return _db.customSelect(sql.toString(), variables: variables).get();
  }
}

/// One search plan: the tables, the predicate and the bound values.
class _SearchPlan {
  const _SearchPlan({
    required this.from,
    required this.join,
    required this.where,
    required this.ayahIdExpr,
    required this.variables,
  });

  /// The table (and alias) the predicate runs against.
  final String from;

  /// The ayah/surah join, using the same alias as [from].
  final String join;

  /// The predicate, with its placeholders.
  final String where;

  /// The expression that yields the global ayah id.
  final String ayahIdExpr;

  /// The bound values for [where], in order.
  final List<Variable<Object>> variables;
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
