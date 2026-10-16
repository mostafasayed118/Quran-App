import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/hadith_browse/hadith_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/hadith_browse/hadith_screen.dart';
import 'package:quran_yahdi/features/library/presentation/hadith_browse/hadith_state.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

Future<void> seedHadithPack(AppDatabase db, Directory tempRoot) async {
  final libraryDir = Directory('${tempRoot.path}/library')
    ..createSync(recursive: true);
  File('test/fixtures/hadith_eng_muslim_excerpt.json')
      .copySync('${libraryDir.path}/en-muslim.json');
  await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
        packId: 'en-muslim',
        kind: 'hadith',
        language: 'en',
        title: 'Sahih Muslim',
        sizeMb: 3.9,
        version: '1',
      ));
}

void main() {
  group('HadithCubit', () {
    late AppDatabase db;
    late Directory tempRoot;

    setUp(() async {
      db = AppDatabase.test(NativeDatabase.memory());
      tempRoot = await Directory.systemTemp.createTemp('qy_hadith_cubit');
      await seedHadithPack(db, tempRoot);
    });

    tearDown(() async {
      await tempRoot.delete(recursive: true);
      await db.close();
    });

    HadithCubit cubit() => HadithCubit(
          downloader:
              PackDownloader(db, libraryRootResolver: () async => tempRoot),
          packId: 'en-muslim',
        );

    Future<HadithReady> readyOf(HadithCubit c) async =>
        await c.stream.firstWhere((s) => s is HadithReady) as HadithReady;

    test('first page windows 10 items with hasMore', () async {
      final c = cubit();
      addTearDown(c.close);
      final ready = await readyOf(c);

      expect(ready.items, hasLength(10));
      expect(ready.offset, 0);
      expect(ready.hasMore, isTrue);
      expect(ready.packTitle, 'Sahih Muslim');
      expect(ready.language, 'en');
    });

    test('next advances the window and flips hasMore at the end', () async {
      final c = cubit();
      addTearDown(c.close);
      final first = await readyOf(c);
      expect(first.hasMore, isTrue);

      await c.next();
      final last = c.state as HadithReady;

      expect(last.items, hasLength(2));
      expect(last.offset, 10);
      expect(last.hasMore, isFalse);
      expect((last.items.first).$1, 11);
    });

    test('prev rewinds to the first window', () async {
      final c = cubit();
      addTearDown(c.close);
      await readyOf(c);
      await c.next();
      await c.prev();
      final back = c.state as HadithReady;

      expect(back.items, hasLength(10));
      expect(back.offset, 0);
      expect(back.hasMore, isTrue);
    });

    test('next on the last window and prev at zero are no-ops', () async {
      final c = cubit();
      addTearDown(c.close);
      await readyOf(c);

      await c.prev();
      final atZero = c.state as HadithReady;
      expect(atZero.offset, 0);

      await c.next();
      await c.next(); // hasMore false here — must not move
      final beyond = c.state as HadithReady;
      expect(beyond.offset, 10);
      expect(beyond.items, hasLength(2));
    });

    test('missing pack resolves an empty page with packId as title', () async {
      final c = HadithCubit(
        downloader:
            PackDownloader(db, libraryRootResolver: () async => tempRoot),
        packId: 'ghost-pack',
      );
      addTearDown(c.close);
      final ready = await readyOf(c);

      expect(ready.items, isEmpty);
      expect(ready.packTitle, 'ghost-pack');
      expect(ready.hasMore, isFalse);
    });

    test('page-fetch failure lands in the error state, never hangs',
        () async {
      final c = HadithCubit(
        downloader: _ThrowingPageDownloader(db),
        packId: 'en-muslim',
      );
      addTearDown(c.close);
      final failure =
          await c.stream.firstWhere((s) => s is HadithError) as HadithError;

      expect(failure.message, isNotEmpty);
      expect(c.state, isA<HadithError>());
    });
  });

  group('HadithScreen', () {
    late AppDatabase db;
    late Directory tempRoot;

    setUp(() async {
      db = AppDatabase.test(NativeDatabase.memory());
      tempRoot = await Directory.systemTemp.createTemp('qy_hadith_screen');
      await seedHadithPack(db, tempRoot);
    });

    tearDown(() async {
      await tempRoot.delete(recursive: true);
      await db.close();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
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
        home: BlocProvider<HadithCubit>(
          create: (_) => HadithCubit(
            downloader:
                PackDownloader(db, libraryRootResolver: () async => tempRoot),
            packId: 'en-muslim',
          ),
          child: const HadithScreen(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('renders the numbered list from the installed pack',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('Sahih Muslim'), findsOneWidget);
      expect(find.textContaining('Zuhayr bin Harb'), findsOneWidget);
      expect(find.text('٣'), findsOneWidget);
    });

    testWidgets('pagination buttons page through the windows', (tester) async {
      await pumpScreen(tester);

      // At offset 0 the prev button is disabled.
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'السابق'),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('التالي'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      // Window 2 (rows 11-12): the fixture text for those rows is empty, so
      // the visible list collapses — row marker ٣ must be gone and prev
      // must now be enabled.
      expect(find.text('٣'), findsNothing);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'السابق'),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.text('السابق'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Zuhayr bin Harb'), findsOneWidget);
    });

    testWidgets('error surface shows localized copy, never the raw message',
        (tester) async {
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
        home: BlocProvider<HadithCubit>.value(
          value: HadithCubit(
            downloader: _ThrowingPageDownloader(db),
            packId: 'en-muslim',
          ),
          child: const HadithScreen(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsOneWidget);
      expect(find.textContaining('page fetch failed'), findsNothing);
    });
  });
}

class _ThrowingPageDownloader extends PackDownloader {
  _ThrowingPageDownloader(super.db);

  @override
  Future<(List<(int, String)>, bool)> hadithPage(
          String packId, int offset, int limit) =>
      Future.error(PackFailure('page fetch failed'));
}
