import 'package:sqlite3/sqlite3.dart';

/// Test fixture: drops the FTS index from a database copy.
///
/// Runs in its own process so the test runner never loads the bundled
/// sqlite3 library, which would keep a Windows lock on the native asset the
/// server process needs to bundle.
void main(List<String> args) {
  final db = sqlite3.open(args.single);
  db.execute('DROP TABLE ayah_search');
  db.close();
}
