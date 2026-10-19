import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db.batch((b) => b.insertAll(db.surahs, [
      SurahsCompanion.insert(
          id: const Value(1), nameAr: 'الفاتحة', nameEn: 'Al-Fatihah',
          revelationType: 'makkah', ayahCount: 7, pagesStart: 1, pagesEnd: 1),
      SurahsCompanion.insert(
          id: const Value(2), nameAr: 'البقرة', nameEn: 'Al-Baqarah',
          revelationType: 'madinah', ayahCount: 286, pagesStart: 2, pagesEnd: 49),
      SurahsCompanion.insert(
          id: const Value(3), nameAr: 'النمل', nameEn: 'An-Naml',
          revelationType: 'makkah', ayahCount: 93, pagesStart: 377, pagesEnd: 385),
    ]));
  });

  Widget host(SurahRepository repo) => BlocProvider<SurahIndexCubit>(
        create: (_) => SurahIndexCubit(repo),
        child: const SurahIndexScreen(),
      );

  Future<void> pumpHost(WidgetTester tester) async {
    final rows = await db.select(db.surahs).get();
    final repo = _TeardownSafeSurahRepository(db, rows);
    await pumpAppHost(tester, home: host(repo));
  }

  testWidgets('rows render arabic names + counts; search filters live',
      (tester) async {
    await pumpHost(tester);

    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('البقرة'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'بقرة');
    await tester.pumpAndSettle();

    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('الفاتحة'), findsNothing);
  });

  testWidgets('number search narrows by surah id', (tester) async {
    await pumpHost(tester);
    await tester.enterText(find.byType(TextField), '2');
    await tester.pumpAndSettle();
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('الفاتحة'), findsNothing);
    expect(find.text('النمل'), findsNothing);
  });
}

class _TeardownSafeSurahRepository extends SurahRepository {
  _TeardownSafeSurahRepository(super.db, this._rows);

  final List<Surah> _rows;

  @override
  Stream<List<Surah>> watchAll() => Stream.value(_rows);
}
