import 'dart:io';

import 'package:drift/native.dart';
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

const Map<String, dynamic> _hadithFixture = {
  'id': 'f-hadith',
  'kind': 'hadith',
  'language': 'en',
  'titleAr': 'حديث تجريبي',
  'titleEn': 'Fixture Hadith',
  'sourceUrl': 'http://127.0.0.1:9/x/h.json',
  'approxSizeMb': 0.001,
  'version': '1',
};

class _InstalledHadithDownloader extends PackDownloader {
  _InstalledHadithDownloader(super.db);

  @override
  Future<List<InstalledPack>> installedPacks() async => <InstalledPack>[
        InstalledPack(
          packId: 'f-hadith',
          kind: 'hadith',
          language: 'en',
          title: 'Fixture Hadith',
          sizeMb: 0.001,
          version: '1',
          installedAt: DateTime(2026),
        ),
      ];

  @override
  Future<File> install(
    LibraryPackInfo pack, {
    void Function(int, int)? onProgress,
  }) async {
    throw UnsupportedError('not used in this test');
  }
}

void main() {
  testWidgets('installed hadith pack exposes the read affordance',
      (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final cubit = LibraryCubit(
      catalog: CatalogRepository(
        source: BundledCatalogSource(
          loader: () async => <Map<String, dynamic>>[_hadithFixture],
        ),
      ),
      downloader: _InstalledHadithDownloader(db),
    );
    addTearDown(cubit.close);

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('الأحاديث'));
    await tester.pumpAndSettle();

    expect(find.text('حديث تجريبي'), findsOneWidget);
    expect(find.byTooltip('اقرأ'), findsOneWidget);
  });
}
