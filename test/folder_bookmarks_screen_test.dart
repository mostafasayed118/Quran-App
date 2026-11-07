import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_meta.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/folder_bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/folder_bookmarks_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

class _Meta implements BookmarkMetaSource {
  @override
  Future<Map<int, BookmarkMetaEntry>> load() async => const {
        9: BookmarkMetaEntry(folder: 'العلم', note: 'ملاحظة قصيرة'),
      };

  @override
  Future<void> save(Map<int, BookmarkMetaEntry> entries) async {}
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'madinah',
          ayahCount: 1,
          pagesStart: 2,
          pagesEnd: 2,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(9),
          surahId: 2,
          numberInSurah: 3,
          juz: 1,
          page: 2,
          textUthmani: 'ذلك الكتاب',
          textImlaei: 'ذلك الكتاب',
        ));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('320 dp at textScale 2.0 survives the folder list',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = FolderBookmarksCubit(
      folder: 'العلم',
      meta: _Meta(),
      ayahs: AyahRepository(db),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await pumpAppHost(
      tester,
      textScale: 2.0,
      home: BlocProvider<FolderBookmarksCubit>.value(
        value: cubit,
        child: const FolderBookmarksScreen(folder: 'العلم'),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('العلم'), findsOneWidget);
    expect(find.text('ذلك الكتاب'), findsOneWidget);
    expect(find.text('ملاحظة قصيرة'), findsOneWidget);
  });
}
