import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/library/data/catalog_repository.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/library_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/library_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

/// The catalog-only screen never installs: the transport is inert.
class _NoopDownloader extends PackDownloader {
  _NoopDownloader(super.db) : super(libraryRootResolver: null);

  @override
  Future<List<InstalledPack>> installedPacks() async => const [];

  @override
  Future<File> install(LibraryPackInfo pack,
      {void Function(int, int)? onProgress}) async {
    throw UnsupportedError('install is not exercised in this test');
  }
}

const Map<String, dynamic> _translationPack = {
  'id': 'f-translation',
  'kind': 'translation',
  'language': 'en',
  'titleAr': 'ترجمة تجريبية',
  'titleEn': 'Fixture Translation',
  'sourceUrl': 'https://127.0.0.1:9/x/t.json',
  'approxSizeMb': 0.001,
  'version': '1',
};

void main() {
  Future<void> pumpLibrary(
    WidgetTester tester,
    List<Map<String, dynamic>> catalog,
  ) async {
    final db = newTestDb();
    final cubit = LibraryCubit(
      catalog: CatalogRepository(
        source: BundledCatalogSource(loader: () async => catalog),
      ),
      downloader: _NoopDownloader(db),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(BlocProvider<LibraryCubit>.value(
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
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  }

  testWidgets('an empty catalog shows one empty state instead of blank tabs',
      (tester) async {
    await pumpLibrary(tester, const []);

    expect(find.text('لا توجد حزم معرفية بعد'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);
  });

  testWidgets('a catalog with a pack keeps the tab bar', (tester) async {
    await pumpLibrary(tester, const [_translationPack]);

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('الترجمات'), findsOneWidget);
    expect(find.text('ترجمة تجريبية'), findsOneWidget);
    expect(find.text('لا توجد حزم معرفية بعد'), findsNothing);
  });
}
