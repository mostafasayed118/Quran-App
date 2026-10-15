import 'package:drift/native.dart';
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

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db, {required this.entries});
  final List<BookmarkEntry> entries;
  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() => Stream.value(entries);
}

BookmarkEntry _entry(AppDatabase db, {required int ayahId, required String text}) {
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
    db = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Widget host(List<BookmarkEntry> entries) =>
      BlocProvider<BookmarksCubit>(
        create: (_) => BookmarksCubit(
            _TeardownSafeAyahRepository(db, entries: entries)),
        child: const BookmarksScreen(),
      );

  Future<void> pump(WidgetTester tester, Widget child) async {
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
      home: child,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('empty state message when no bookmarks', (tester) async {
    await pump(tester, host(const []));
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('lists entries with verse info and removes on delete', (tester) async {
    final text = 'ذلك الكتاب لا ريب فيه';
    final repo = _TeardownSafeAyahRepository(
      db,
      entries: [_entry(db, ayahId: 9, text: text)],
    );
    // Seed one row so the real delete has something to remove.
    await db.into(db.bookmarks)
        .insert(BookmarksCompanion.insert(ayahId: 9));
    final cubit = BookmarksCubit(repo);
    await pump(
      tester,
      BlocProvider<BookmarksCubit>.value(value: cubit, child: const BookmarksScreen()),
    );

    expect(find.textContaining(text), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(await db.select(db.bookmarks).get(), isEmpty);
  });

}
