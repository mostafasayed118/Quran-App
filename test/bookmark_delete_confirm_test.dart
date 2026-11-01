import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
            id: const Value(2),
            nameAr: 'البقرة',
            nameEn: 'Al-Baqarah',
            revelationType: 'madani',
            ayahCount: 286,
            pagesStart: 2,
            pagesEnd: 49,
          ),
        );
    await db.into(db.ayahs).insert(
          AyahsCompanion.insert(
            id: const Value(9),
            surahId: 2,
            numberInSurah: 2,
            juz: 1,
            page: 2,
            textUthmani: 'ذلك الكتاب',
            textImlaei: 'ذلك الكتاب',
          ),
        );
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 9));
  });

  Future<void> pumpBookmarks(WidgetTester tester) async {
    final cubit = BookmarksCubit(AyahRepository(db));
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(BlocProvider<BookmarksCubit>.value(
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
        home: const BookmarksScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('delete asks first and leaves the bookmark in place',
      (tester) async {
    await pumpBookmarks(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('ستُحذف هذه العلامة من قائمتك.'), findsOneWidget);
    expect(await db.select(db.bookmarks).get(), hasLength(1),
        reason: 'opening the dialog must not delete anything');
  });

  testWidgets('cancelling the dialog keeps the bookmark', (tester) async {
    await pumpBookmarks(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(await db.select(db.bookmarks).get(), hasLength(1));
    expect(find.text('ذلك الكتاب'), findsOneWidget);
  });

  testWidgets('confirming the dialog removes the bookmark', (tester) async {
    await pumpBookmarks(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();

    expect(await db.select(db.bookmarks).get(), isEmpty);
    expect(find.text('ذلك الكتاب'), findsNothing);
  });
}
