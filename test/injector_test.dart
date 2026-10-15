import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/di/injector.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  final String path;

  _TempSupportPathProvider(this.path);

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // path_provider has no platform channel under pure flutter_test —
    // route it to a temp dir so the real-file database can open.
    final tmp = Directory.systemTemp.createTempSync('quran_yahdi_db_test');
    PathProviderPlatform.instance = _TempSupportPathProvider(tmp.path);
  });

  test('configureDependencies registers a working AppDatabase', () async {
    await configureDependencies();
    final db = getIt<AppDatabase>();
    final row = await db.customSelect('SELECT 1 AS one').getSingle();
    expect(row.read<int>('one'), 1);
  });
}
