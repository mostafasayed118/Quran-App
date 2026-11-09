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

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db, {required this.entries});
  final List<BookmarkEntry> entries;
  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() => Stream.value(entries);
}

BookmarkEntry _entry(AppDatabase db,
    {required int ayahId, required String text}) {
  return BookmarkEntry(
    ayah: Ayah(
      id: ayahId,
      surahId: 2,
      numberInSurah: ayahId,
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

  setUp(() {
    db = newTestDb();
  });

  Future<Widget> host(List<BookmarkEntry> entries) async {
    final cubit =
        BookmarksCubit(_TeardownSafeAyahRepository(db, entries: entries));
    addTearDown(cubit.close);
    await cubit.start();
    return BlocProvider<BookmarksCubit>.value(
      value: cubit,
      child: const BookmarksScreen(),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double? textScale,
  }) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      builder: textScale == null
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
      home: child,
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  }

  testWidgets('empty state message when no bookmarks', (tester) async {
    await pump(tester, await host(const []));
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('lists entries with verse info and removes on delete',
      (tester) async {
    final text = 'ذلك الكتاب لا ريب فيه';
    final repo = _TeardownSafeAyahRepository(
      db,
      entries: [_entry(db, ayahId: 9, text: text)],
    );
    // Seed one row so the real delete has something to remove.
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 9));
    final cubit = BookmarksCubit(repo);
    await cubit.start();
    await pump(
      tester,
      BlocProvider<BookmarksCubit>.value(
          value: cubit, child: const BookmarksScreen()),
    );

    expect(find.textContaining(text), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    // Owner-requested behaviour change: deleting a bookmark now asks first.
    await tester.tap(find.widgetWithText(TextButton, 'حذف'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    expect(await db.select(db.bookmarks).get(), isEmpty);
  });

  testWidgets('delete button exposes a tooltip (a11y label census)',
      (tester) async {
    final text = 'ذلك الكتاب لا ريب فيه';
    await pump(tester, await host([_entry(db, ayahId: 9, text: text)]));
    expect(find.byTooltip('أزل الحفظ'), findsOneWidget);
  });

  testWidgets('320 dp at textScale 2.0 survives the bookmark list',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const text = 'ذلك الكتاب لا ريب فيه';
    await pump(
      tester,
      await host([_entry(db, ayahId: 9, text: text)]),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining(text), findsOneWidget);
  });
}
