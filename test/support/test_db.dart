import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:drift/src/runtime/executor/interceptor.dart'
    show ApplyInterceptor;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';

/// Per-test in-memory database (setUp / test-body scope only); it closes
/// itself at test end via addTearDown — callers must not close it again.
AppDatabase newTestDb() {
  final db = AppDatabase.test(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

/// A test DB that fails any statement binding more than [limit] variables,
/// emulating the Android SQLite `SQLITE_MAX_VARIABLE_NUMBER = 999` ceiling on
/// hosts whose bundled SQLite allows far more (so an un-batched IN list does
/// not pass the suite by accident).
AppDatabase newLimitedVarDb({int limit = 3}) {
  final db = AppDatabase.test(
    NativeDatabase.memory().interceptWith(_VariableLimit(limit)),
  );
  addTearDown(db.close);
  return db;
}

class _VariableLimit extends QueryInterceptor {
  _VariableLimit(this.limit);
  final int limit;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (args.length > limit) {
      throw StateError('too many SQL variables: ${args.length} > $limit');
    }
    return executor.runSelect(statement, args);
  }
}
