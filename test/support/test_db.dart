import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';

/// Per-test in-memory database (setUp / test-body scope only); it closes
/// itself at test end via addTearDown — callers must not close it again.
AppDatabase newTestDb() {
  final db = AppDatabase.test(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}
