import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/connection.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  _TempSupportPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final tmp = Directory.systemTemp.createTempSync('qy_wal');
    PathProviderPlatform.instance = _TempSupportPathProvider(tmp.path);
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
  });

  /// Opens the production database path (asset copy + WAL setup are shared
  /// with the app) and reads back the effective journal mode.
  Future<String> journalMode() async {
    final db = AppDatabase(await openAppDatabase());
    try {
      final row = await db.customSelect('PRAGMA journal_mode').getSingle();
      return row.data.values.first.toString().toLowerCase();
    } finally {
      await db.close();
    }
  }

  test('production open enables WAL journal mode', () async {
    expect(await journalMode(), 'wal');
  });

  test('reopening the same database file stays in WAL mode', () async {
    expect(await journalMode(), 'wal');
    expect(await journalMode(), 'wal');
  });
}
