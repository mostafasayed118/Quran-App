import '../../../core/db/app_database.dart';
import '../domain/juz_summary.dart';
import 'juz_index_source.dart';

/// Reads the 30 juz starts from the shipped ayah table.
///
/// The juz boundaries are page/ayah aligned and already in the schema, so this
/// is a read-only derivation — no schema change and no invented data.
class JuzRepository implements JuzIndexSource {
  /// Creates the repository over [db].
  JuzRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<JuzSummary>> watchJuz() {
    return _db
        .customSelect(
          'SELECT a.juz AS juz, a.page AS first_page, a.surah_id AS surah_id, '
          'a.number_in_surah AS number_in_surah, s.name_ar AS surah_name '
          'FROM ayahs a '
          'JOIN (SELECT juz, MIN(id) AS min_id FROM ayahs GROUP BY juz) m '
          'ON a.id = m.min_id '
          'JOIN surahs s ON s.id = a.surah_id '
          'ORDER BY a.juz',
          readsFrom: {_db.ayahs, _db.surahs},
        )
        .watch()
        .map(
          (rows) => List<JuzSummary>.unmodifiable(
            rows.map(
              (row) => JuzSummary(
                juz: row.read<int>('juz'),
                firstPage: row.read<int>('first_page'),
                surahId: row.read<int>('surah_id'),
                numberInSurah: row.read<int>('number_in_surah'),
                surahName: row.read<String>('surah_name'),
              ),
            ),
          ),
        );
  }
}
