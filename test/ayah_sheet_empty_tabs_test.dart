import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/ayah_sheet/library_sheet.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

/// FakeAsync-safe pack decoder: isolate completions never arrive under the
/// widget-test zone, so these tests use the PackDownloader decoder seam.
Future<dynamic> _syncDecode(String path) async =>
    jsonDecode(File(path).readAsStringSync());

const _tafsirPackId = 'ar-tafsir-muyassar';
const _translationPackId = 'ar-sirajtafseer';

/// Installs the REAL fixture excerpts for the kinds the case asks for; a kind
/// left out is simply absent, which is what the shipped catalog looks like.
Future<void> _installPacks(
  AppDatabase db,
  Directory tempRoot, {
  required bool tafsir,
  required bool translation,
}) async {
  final libraryDir = Directory('${tempRoot.path}/library')
    ..createSync(recursive: true);
  if (tafsir) {
    File('test/fixtures/tafsir_wrapper_sample.json')
        .copySync('${libraryDir.path}/$_tafsirPackId.json');
    await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
          packId: _tafsirPackId,
          kind: 'tafsir',
          language: 'ar',
          title: 'التفسير الميسر',
          sizeMb: 0.2,
          version: 'v1.2.2',
        ));
  }
  if (translation) {
    File('test/fixtures/translation_ara_sirajtafseer_excerpt.json')
        .copySync('${libraryDir.path}/$_translationPackId.json');
    await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
          packId: _translationPackId,
          kind: 'translation',
          language: 'ar',
          title: 'السراج المنير',
          sizeMb: 2.0,
          version: '1',
        ));
  }
}

void main() {
  final loc = lookupAppLocalizations(const Locale('ar'));

  late AppDatabase db;
  late Directory tempRoot;
  late PackDownloader downloader;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    tempRoot = await Directory.systemTemp.createTemp('qy_ayah_sheet_tabs');
    downloader = PackDownloader(db,
        libraryRootResolver: () async => tempRoot, fileDecoder: _syncDecode);
  });

  tearDown(() async {
    await db.close();
    await tempRoot.delete(recursive: true);
  });

  Future<void> pumpSheet(WidgetTester tester) async {
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
      home: Scaffold(
        body: AyahSheet(
          surahId: 1,
          surahName: 'الفاتحة',
          ayah: 1,
          downloader: downloader,
        ),
      ),
    ));
    // Bounded pumps only: pumpAndSettle can hang while drift loads.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
  }

  List<Tab> tabsOf(WidgetTester tester) =>
      tester.widgetList<Tab>(find.byType(Tab)).toList();

  testWidgets('no tafsir entries hides the tafsir tab', (tester) async {
    await tester.runAsync(
      () => _installPacks(db, tempRoot, tafsir: false, translation: true),
    );
    await pumpSheet(tester);

    final tabs = tabsOf(tester);
    expect(tabs, hasLength(1));
    expect(tabs.single.text, loc.ayahSheetTranslation);
    expect(find.text(loc.ayahSheetTafsir), findsNothing);
    expect(find.text(loc.ayahSheetTranslation), findsOneWidget);
  });

  testWidgets('no translation entries hides the translation tab',
      (tester) async {
    await tester.runAsync(
      () => _installPacks(db, tempRoot, tafsir: true, translation: false),
    );
    await pumpSheet(tester);

    final tabs = tabsOf(tester);
    expect(tabs, hasLength(1));
    expect(tabs.single.text, loc.ayahSheetTafsir);
    expect(find.text(loc.ayahSheetTranslation), findsNothing);
    expect(find.text(loc.ayahSheetTafsir), findsOneWidget);
  });

  testWidgets('both kinds keep two tabs', (tester) async {
    await tester.runAsync(
      () => _installPacks(db, tempRoot, tafsir: true, translation: true),
    );
    await pumpSheet(tester);

    final tabs = tabsOf(tester);
    expect(tabs, hasLength(2));
    expect(tabs.map((tab) => tab.text),
        containsAll(<String>[loc.ayahSheetTafsir, loc.ayahSheetTranslation]));
  });

  testWidgets('nothing installed keeps exactly the translation tab',
      (tester) async {
    await pumpSheet(tester);

    final tabs = tabsOf(tester);
    expect(tabs, hasLength(1));
    expect(tabs.single.text, loc.ayahSheetTranslation);
    expect(find.text(loc.ayahSheetTafsir), findsNothing);
    expect(find.text(loc.libraryEmptyHint), findsOneWidget);
  });
}
