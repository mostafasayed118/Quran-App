import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/catalog_repository.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/library_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/library_state.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDb();
  });

  test('catalog load failure lands in the failed state, not a hang', () async {
    final cubit = LibraryCubit(
      catalog: CatalogRepository(
        source:
            BundledCatalogSource(loader: () async => throw StateError('boom')),
      ),
      downloader: PackDownloader(db),
    );
    expect(cubit.state, isA<LibraryLoading>());

    await cubit.start();
    expect(cubit.state, isA<LibraryFailed>());
    expect((cubit.state as LibraryFailed).message, isNotEmpty);

    await cubit.close();
  });

  test('a good catalog still reaches ready', () async {
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
      downloader: PackDownloader(db),
    );

    await cubit.start();
    expect(cubit.state, isA<LibraryReady>());

    await cubit.close();
  });
}
