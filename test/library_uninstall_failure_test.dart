import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/catalog_repository.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/library_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/library_state.dart';

import 'support/test_db.dart';

class _ThrowingUninstallDownloader extends PackDownloader {
  _ThrowingUninstallDownloader(super.db);

  @override
  Future<void> uninstall(String packId) async {
    throw StateError('uninstall transport down');
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDb();
  });

  test('a throwing uninstall keeps the ready state and marks the pack failed',
      () async {
    final cubit = LibraryCubit(
      catalog: CatalogRepository(
        source: BundledCatalogSource(
          loader: () async => [
            {
              'id': 'p1',
              'kind': 'translation',
              'language': 'ar',
              'titleAr': 'ع',
              'titleEn': 'x',
              'sourceUrl': 'https://cdn.jsdelivr.net/gh/a/b@1/x.json',
              'approxSizeMb': 1.0,
              'version': '1',
            },
          ],
        ),
      ),
      downloader: _ThrowingUninstallDownloader(db),
    );
    addTearDown(cubit.close);
    await cubit.start();
    expect(cubit.state, isA<LibraryReady>());

    await cubit.uninstall('p1');

    final ready = cubit.state as LibraryReady;
    expect(ready.failed, contains('p1'));
    expect(ready.installed, isNot(contains('p1')));
  });
}
