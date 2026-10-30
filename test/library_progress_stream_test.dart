import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/catalog_repository.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/library_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/library_state.dart';

import 'support/test_db.dart';

class _ProgressDownloader extends PackDownloader {
  _ProgressDownloader(super.db) : super(libraryRootResolver: null);

  final StreamController<Map<String, (int, int)>> controller =
      StreamController<Map<String, (int, int)>>.broadcast();
  Map<String, (int, int)> current = {};

  @override
  Map<String, (int, int)> get progress => Map.unmodifiable(current);

  @override
  Stream<Map<String, (int, int)>> get progressStream => controller.stream;

  @override
  Future<List<InstalledPack>> installedPacks() async => const [];
}

CatalogRepository _emptyCatalog() => CatalogRepository(
      source: BundledCatalogSource(loader: () async => const []),
    );

void main() {
  late AppDatabase db;
  late _ProgressDownloader downloader;

  setUp(() {
    db = newTestDb();
    downloader = _ProgressDownloader(db);
  });

  tearDown(() async {
    await downloader.controller.close();
    await db.close();
  });

  test('a re-entering cubit seeds progress from the app-scoped downloader',
      () async {
    downloader.current = {'p': (3, 10)};
    final cubit =
        LibraryCubit(catalog: _emptyCatalog(), downloader: downloader);
    addTearDown(cubit.close);

    await cubit.start();

    expect((cubit.state as LibraryReady).progress['p'], (3, 10));
  });

  test('live downloader progress is mirrored into the route cubit', () async {
    final cubit =
        LibraryCubit(catalog: _emptyCatalog(), downloader: downloader);
    addTearDown(cubit.close);
    await cubit.start();

    downloader.controller.add({'p': (7, 10)});
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as LibraryReady).progress['p'], (7, 10));
  });
}
