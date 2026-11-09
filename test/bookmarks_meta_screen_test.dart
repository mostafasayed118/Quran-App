import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_meta.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmark_meta_cubit.dart';
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

class _MetaSource implements BookmarkMetaSource {
  _MetaSource(this.entries);

  Map<int, BookmarkMetaEntry> entries;

  @override
  Future<Map<int, BookmarkMetaEntry>> load() async => entries;

  @override
  Future<void> save(Map<int, BookmarkMetaEntry> next) async {
    entries = next;
  }
}

BookmarkEntry _entry(String text) => BookmarkEntry(
      ayah: Ayah(
        id: 9,
        surahId: 2,
        numberInSurah: 2,
        juz: 1,
        page: 2,
        textUthmani: text,
        textImlaei: text,
        sajda: false,
      ),
    );

void main() {
  testWidgets('shows the folder chip, the note and edits the note',
      (tester) async {
    final db = newTestDb();
    final source = _MetaSource({
      9: const BookmarkMetaEntry(folder: 'تفسير', note: 'ملاحظة قديمة'),
    });
    final bookmarks = BookmarksCubit(
      _TeardownSafeAyahRepository(db, entries: [_entry('ذلك الكتاب')]),
    );
    final meta = BookmarkMetaCubit(source: source);
    addTearDown(bookmarks.close);
    addTearDown(meta.close);
    await bookmarks.start();
    await meta.start();

    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<BookmarksCubit>.value(value: bookmarks),
        BlocProvider<BookmarkMetaCubit>.value(value: meta),
      ],
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
        home: const BookmarksScreen(showMeta: true),
      ),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.text('تفسير'), findsWidgets);
    expect(find.text('ملاحظة قديمة'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    expect(find.text('تعديل الملاحظة والمجلد'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), 'ملاحظة جديدة');
    await tester.tap(find.widgetWithText(TextButton, 'حفظ'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(source.entries[9]?.note, 'ملاحظة جديدة');
    expect(find.text('ملاحظة جديدة'), findsOneWidget);
  });
}
