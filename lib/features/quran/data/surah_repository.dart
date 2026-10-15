import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

class SurahRepository {
  SurahRepository(this._db);

  final AppDatabase _db;

  Stream<List<Surah>> watchAll() {
    final q = _db.select(_db.surahs)
      ..orderBy([(s) => OrderingTerm.asc(s.id)]);
    return q.watch();
  }
}
