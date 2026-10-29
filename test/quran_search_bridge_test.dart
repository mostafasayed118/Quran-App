import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/quran_search_source.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_screen.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/search/quran_search_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

/// Records every query the screen runs, so the hand-over can be asserted.
class _RecordingSource implements QuranSearchSource {
  final List<String> queries = <String>[];

  @override
  Future<QuranSearchPage> search(
    String query, {
    int? afterAyahId,
    int limit = kQuranSearchPageSize,
  }) async {
    queries.add(query);
    return const QuranSearchPage(
      hits: [
        QuranSearchHit(
          ayahId: 10,
          surahId: 2,
          numberInSurah: 3,
          surahNameAr: 'البقرة',
          textImlaei: 'الذين يؤمنون بالغيب',
        ),
      ],
      total: 1,
      hasMore: false,
    );
  }
}

/// The frozen suite's teardown-safe wrapper shape: override the row stream
/// and let the base map rows to summaries.
class _SafeSurahRepository extends SurahRepository {
  _SafeSurahRepository(super.db, this._rows);
  final List<Surah> _rows;

  @override
  Stream<List<Surah>> watchAll() => Stream.value(_rows);
}

void main() {
  testWidgets('an initial query runs the search and prefills the field',
      (tester) async {
    final source = _RecordingSource();
    await pumpAppHost(
      tester,
      home: BlocProvider<QuranSearchCubit>(
        create: (_) => QuranSearchCubit(source),
        child: const QuranSearchScreen(initialQuery: 'الرحمن'),
      ),
    );
    await tester.pumpAndSettle();

    expect(source.queries, ['الرحمن'],
        reason: 'the handed-over query must run without typing');
    expect(find.text('الرحمن'), findsOneWidget);
    expect(find.textContaining('البقرة'), findsWidgets);
  });

  testWidgets('a filter with no surah match offers the verse search',
      (tester) async {
    final db = newTestDb();
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
    final cubit = SurahIndexCubit(
        _SafeSurahRepository(db, await db.select(db.surahs).get()));
    addTearDown(cubit.close);
    await cubit.start();

    await pumpAppHost(
      tester,
      home: BlocProvider<SurahIndexCubit>.value(
        value: cubit,
        child: const SurahIndexScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'الرحمن');
    await tester.pumpAndSettle();

    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
    expect(find.textContaining('ابحث عن'), findsOneWidget,
        reason: 'a dead-end filter must offer the verse search');
  });
}
