import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/juz_index_source.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/domain/juz_summary.dart';
import 'package:quran_yahdi/features/quran/domain/surah_summary.dart';
import 'package:quran_yahdi/features/quran/domain/verse.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_body.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/juz_index_body.dart';
import 'package:quran_yahdi/features/quran/presentation/index/juz_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_body.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';

import 'support/host.dart';
import 'support/test_db.dart';

class _JuzSource implements JuzIndexSource {
  const _JuzSource();

  @override
  Stream<List<JuzSummary>> watchJuz() => Stream.value(const [
        JuzSummary(
          juz: 1,
          firstPage: 1,
          surahId: 1,
          numberInSurah: 1,
          surahName: 'الفاتحة',
        ),
        JuzSummary(
          juz: 2,
          firstPage: 22,
          surahId: 2,
          numberInSurah: 142,
          surahName: 'البقرة',
        ),
      ]);
}

class _BookmarkRepository extends AyahRepository {
  _BookmarkRepository(super.db, {required this.entries});

  final List<BookmarkEntry> entries;

  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() => Stream.value(entries);
}

BookmarkEntry _bookmark({
  required int ayahId,
  required int numberInSurah,
  required String text,
}) {
  return BookmarkEntry(
    ayah: Ayah(
      id: ayahId,
      surahId: 2,
      numberInSurah: numberInSurah,
      juz: 1,
      page: 2,
      textUthmani: text,
      textImlaei: text,
      sajda: false,
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db.batch((b) => b.insertAll(db.surahs, [
          SurahsCompanion.insert(
              id: const Value(1),
              nameAr: 'الفاتحة',
              nameEn: 'Al-Fatihah',
              revelationType: 'makkah',
              ayahCount: 7,
              pagesStart: 1,
              pagesEnd: 1),
          SurahsCompanion.insert(
              id: const Value(2),
              nameAr: 'البقرة',
              nameEn: 'Al-Baqarah',
              revelationType: 'madinah',
              ayahCount: 286,
              pagesStart: 2,
              pagesEnd: 49),
        ]));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('SurahIndexBody reports the tapped surah', (tester) async {
    final cubit = SurahIndexCubit(SurahRepository(db));
    addTearDown(cubit.close);
    await cubit.start();
    SurahSummary? selected;

    await pumpAppHost(
      tester,
      home: Scaffold(
        body: BlocProvider<SurahIndexCubit>.value(
          value: cubit,
          child: SurahIndexBody(onSelect: (surah) => selected = surah),
        ),
      ),
    );

    await tester.tap(find.text('الفاتحة'));
    await tester.pump();

    expect(selected?.id, 1);
    expect(selected?.nameAr, 'الفاتحة');
  });

  testWidgets('JuzIndexBody reports the tapped juz', (tester) async {
    final cubit = JuzIndexCubit(source: const _JuzSource());
    addTearDown(cubit.close);
    await cubit.start();
    JuzSummary? selected;

    await pumpAppHost(
      tester,
      home: Scaffold(
        body: BlocProvider<JuzIndexCubit>.value(
          value: cubit,
          child: JuzIndexBody(onSelect: (juz) => selected = juz),
        ),
      ),
    );

    await tester.tap(find.text('الجزء ١'));
    await tester.pump();

    expect(selected?.juz, 1);
    expect(selected?.surahId, 1);
  });

  testWidgets('BookmarksBody reports the tapped verse', (tester) async {
    final cubit = BookmarksCubit(_BookmarkRepository(
      db,
      entries: [
        _bookmark(ayahId: 9, numberInSurah: 2, text: 'ذلك الكتاب'),
      ],
    ));
    addTearDown(cubit.close);
    await cubit.start();
    Verse? selected;

    await pumpAppHost(
      tester,
      home: Scaffold(
        body: BlocProvider<BookmarksCubit>.value(
          value: cubit,
          child: BookmarksBody(onSelect: (verse) => selected = verse),
        ),
      ),
    );

    await tester.tap(find.text('ذلك الكتاب'));
    await tester.pump();

    expect(selected?.numberInSurah, 2);
    expect(selected?.surahId, 2);
  });
}
