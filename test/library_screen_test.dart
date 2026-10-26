import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/library/data/catalog_repository.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/library_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/library_screen.dart';
import 'package:quran_yahdi/features/library/presentation/library_state.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

List<Map<String, dynamic>> fixtureCatalog() => [
      {
        'id': 'f-tafsir',
        'kind': 'tafsir',
        'language': 'ar',
        'titleAr': 'تفسير تجريبي',
        'titleEn': 'Fixture Tafsir',
        'urlTemplate': 'https://127.0.0.1:9/x/{n}.json',
        'fileCount': 2,
        'approxSizeMb': 0.001,
        'version': 'v1',
      },
      {
        'id': 'f-translation',
        'kind': 'translation',
        'language': 'en',
        'titleAr': 'ترجمة تجريبية',
        'titleEn': 'Fixture Translation',
        'sourceUrl': 'https://127.0.0.1:9/x/t.json',
        'approxSizeMb': 0.001,
        'version': '1',
      },
      {
        'id': 'f-hadith',
        'kind': 'hadith',
        'language': 'en',
        'titleAr': 'حديث تجريبي',
        'titleEn': 'Fixture Hadith',
        'sourceUrl': 'https://127.0.0.1:9/x/h.json',
        'approxSizeMb': 0.001,
        'version': '1',
      },
    ];

/// Widget-test transport: drives REAL PackDownloader against a REAL temp
/// file with manually-paced progress (dio/network stays out of FakeAsync;
/// real streaming is covered in pack_downloader_test).
class StreamingFakeDownloader extends PackDownloader {
  StreamingFakeDownloader(super.db, this.root);

  final Directory root;
  Completer<void>? gate;

  @override
  Future<File> install(LibraryPackInfo pack,
      {void Function(int, int)? onProgress}) async {
    onProgress?.call(412, 1049);
    final g = gate;
    if (g != null) {
      await g.future;
    }
    final dir = Directory('${root.path}/library')..createSync(recursive: true);
    final file = File('${dir.path}/${pack.id}.json')
      ..writeAsStringSync(
          '{"quran":[{"chapter":1,"verse":1,"text":"text one"}]}');
    onProgress?.call(1049, 1049);
    return file;
  }

  @override
  Future<List<InstalledPack>> installedPacks() async => const [];
}

/// Controllable fake: records calls, the test decides success/failure and
/// drives progress manually.
class ControllableFakeDownloader extends PackDownloader {
  ControllableFakeDownloader(super.db) : super(libraryRootResolver: null);

  final Set<String> uninstalled = <String>{};
  final List<void Function(int, int)> capturedProgress =
      <void Function(int, int)>[];
  Object? nextFailureOrProgressMode;

  @override
  Future<File> install(LibraryPackInfo pack,
      {void Function(int, int)? onProgress}) async {
    if (onProgress != null) {
      capturedProgress.add(onProgress);
    }
    final failure = nextFailureOrProgressMode;
    if (failure is Object && failure is! int) {
      throw failure;
    }
    return File('${Directory.systemTemp.path}/${pack.id}.json');
  }

  @override
  Future<List<InstalledPack>> installedPacks() async => const [];

  @override
  Future<void> uninstall(String packId) async {
    uninstalled.add(packId);
  }
}

void main() {
  group('LibraryCubit', () {
    late AppDatabase db;
    setUp(() async {
      db = AppDatabase.test(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    test('loads all catalog packs into ready state', () async {
      final cubit = LibraryCubit(
        catalog: CatalogRepository(
          source: BundledCatalogSource(loader: () async => fixtureCatalog()),
        ),
        downloader: ControllableFakeDownloader(db),
      );
      addTearDown(cubit.close);
      await cubit.start();

      final state = cubit.state as LibraryReady;
      expect(state.packs, hasLength(3));
      expect(state.installed, isEmpty);
      expect(state.failed, isEmpty);
    });

    test('install flows progress then flips installed', () async {
      final fake = ControllableFakeDownloader(db);
      final cubit = LibraryCubit(
        catalog: CatalogRepository(
          source: BundledCatalogSource(loader: () async => fixtureCatalog()),
        ),
        downloader: fake,
      );
      addTearDown(cubit.close);
      await cubit.start();

      final pack = (cubit.state as LibraryReady).packs.first;
      final installing = cubit.install(pack);
      expect((cubit.state as LibraryReady).progress[pack.id], isNotNull);

      // fake install captured the callback; complete the flow
      final state0 = cubit.state as LibraryReady;
      expect(state0.progress[pack.id]!.$2, (0.001 * 1024 * 1024).round());
      await installing;
      final ready = cubit.state as LibraryReady;
      expect(ready.installed, contains(pack.id));
      expect(ready.progress[pack.id], isNull);
    });

    test('install failure marks failed; retry clears and installs', () async {
      final fake = ControllableFakeDownloader(db);
      fake.nextFailureOrProgressMode = PackFailure('boom');
      final cubit = LibraryCubit(
        catalog: CatalogRepository(
          source: BundledCatalogSource(loader: () async => fixtureCatalog()),
        ),
        downloader: fake,
      );
      addTearDown(cubit.close);
      await cubit.start();

      final pack = (cubit.state as LibraryReady).packs.first;
      await cubit.install(pack);
      expect((cubit.state as LibraryReady).failed, contains(pack.id));

      fake.nextFailureOrProgressMode = null;
      await cubit.retry(pack.id);
      final ready = cubit.state as LibraryReady;
      expect(ready.failed, isNot(contains(pack.id)));
      expect(ready.installed, contains(pack.id));
    });

    test('uninstall removes the id from the installed set', () async {
      final fake = ControllableFakeDownloader(db);
      final cubit = LibraryCubit(
        catalog: CatalogRepository(
          source: BundledCatalogSource(loader: () async => fixtureCatalog()),
        ),
        downloader: fake,
      );
      addTearDown(cubit.close);
      await cubit.start();

      final pack = (cubit.state as LibraryReady).packs.first;
      await cubit.install(pack);
      expect((cubit.state as LibraryReady).installed, contains(pack.id));

      await cubit.uninstall(pack.id);
      expect((cubit.state as LibraryReady).installed, isNot(contains(pack.id)));
      expect(fake.uninstalled, contains(pack.id));
    });
  });

  group('LibraryScreen', () {
    late AppDatabase db;
    late Directory tempRoot;

    setUp(() async {
      db = AppDatabase.test(NativeDatabase.memory());
      tempRoot = await Directory.systemTemp.createTemp('qy_library_screen');
    });
    tearDown(() async {
      await tempRoot.delete(recursive: true);
      await db.close();
    });

    LibraryCubit screenCubit(AppDatabase db,
        {required CatalogRepository catalog,
        required PackDownloader downloader}) {
      final cubit = LibraryCubit(catalog: catalog, downloader: downloader);
      addTearDown(cubit.close);
      return cubit;
    }

    Widget screen(LibraryCubit cubit) => BlocProvider<LibraryCubit>.value(
          value: cubit,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light,
            home: const LibraryScreen(),
          ),
        );

    testWidgets('renders tabs and fixture pack rows per kind', (tester) async {
      final cubit = screenCubit(
        db,
        catalog: CatalogRepository(
          source: BundledCatalogSource(loader: () async => fixtureCatalog()),
        ),
        downloader: ControllableFakeDownloader(db),
      );
      await cubit.start();

      await tester.pumpWidget(screen(cubit));
      await tester.pumpAndSettle();

      expect(find.text('التفسير'), findsOneWidget);
      expect(find.text('الترجمات'), findsOneWidget);
      expect(find.text('الأحاديث'), findsOneWidget);
      expect(find.text('تفسير تجريبي'), findsOneWidget);

      await tester.tap(find.text('الترجمات'));
      await tester.pumpAndSettle();
      expect(find.text('ترجمة تجريبية'), findsOneWidget);
    });

    testWidgets(
        'install row: button -> progress -> installed badge (real file)',
        (tester) async {
      final catalogPack = {
        'id': 'real-stream',
        'kind': 'translation',
        'language': 'en',
        'titleAr': 'ترجمة حقيقية',
        'titleEn': 'Real Stream Pack',
        'sourceUrl': 'https://widget-test.invalid/x.min.json',
        'approxSizeMb': 0.001,
        'version': '1',
      };
      final downloader = StreamingFakeDownloader(db, tempRoot);
      final cubit = screenCubit(
        db,
        catalog: CatalogRepository(
          source: BundledCatalogSource(loader: () async => [catalogPack]),
        ),
        downloader: downloader,
      );
      await cubit.start();

      await tester.pumpWidget(screen(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('الترجمات'));
      await tester.pumpAndSettle();
      downloader.gate = Completer<void>();
      await tester.tap(find.text('تنزيل').first);
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget,
          reason: 'progress becomes visible while the stream runs');
      downloader.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('مثبّت'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(
        File('${tempRoot.path}/library/real-stream.json').existsSync(),
        isTrue,
      );
    });
  });
}
