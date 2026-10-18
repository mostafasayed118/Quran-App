import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'surah_source.dart';

class SurahRepository implements SurahSource {
  SurahRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Surah>> watchAll() {
    final q = _db.select(_db.surahs)..orderBy([(s) => OrderingTerm.asc(s.id)]);
    return q.watch();
  }
}
