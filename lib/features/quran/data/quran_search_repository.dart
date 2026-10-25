import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'quran_search_source.dart';

/// Reads Quran search results from the derived `ayah_search` index.
class QuranSearchRepository implements QuranSearchSource {
  QuranSearchRepository(this._db);

  final AppDatabase _db;

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
    final clauses = [for (final _ in tokens) 'text_norm LIKE ?'];
    final args = <Object?>[for (final token in tokens) '%$token%'];
    final total = await _count(clauses, args);
    final rows = await _rows(clauses, args, afterAyahId, limit + 1);
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

  Future<int> _count(List<String> clauses, List<Object?> args) async {
    final row = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM ayah_search WHERE ${clauses.join(' AND ')}',
      variables: [for (final arg in args) Variable(arg)],
    ).getSingle();
    return row.read<int>('c');
  }

  Future<List<QueryRow>> _rows(
    List<String> clauses,
    List<Object?> args,
    int? afterAyahId,
    int fetch,
  ) async {
    final sql = StringBuffer('SELECT s.ayah_id, a.surah_id, a.number_in_surah, '
        'u.name_ar, a.text_imlaei '
        'FROM ayah_search s '
        'JOIN ayahs a ON a.id = s.ayah_id '
        'JOIN surahs u ON u.id = a.surah_id '
        'WHERE ${clauses.join(' AND ')}');
    final variables = <Variable<Object>>[
      for (final arg in args) Variable<Object>(arg),
    ];
    if (afterAyahId != null) {
      sql.write(' AND s.ayah_id > ?');
      variables.add(Variable<int>(afterAyahId));
    }
    sql.write(' ORDER BY s.ayah_id LIMIT ?');
    variables.add(Variable<int>(fetch));
    return _db.customSelect(sql.toString(), variables: variables).get();
  }
}
