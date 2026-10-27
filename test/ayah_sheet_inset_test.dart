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

Future<dynamic> _syncDecode(String path) async =>
    jsonDecode(File(path).readAsStringSync());

Future<void> _seedPacks(AppDatabase db, Directory tempRoot) async {
  final libraryDir = Directory('${tempRoot.path}/library')
    ..createSync(recursive: true);
  File('test/fixtures/tafsir_wrapper_sample.json')
      .copySync('${libraryDir.path}/ar-tafsir-muyassar.json');
  await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
        packId: 'ar-tafsir-muyassar',
        kind: 'tafsir',
        language: 'ar',
        title: 'التفسير الميسر',
        sizeMb: 0.2,
        version: 'v1.2.2',
      ));
}

const double kHeight = 800;
const double kInset = 48;

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late PackDownloader downloader;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    tempRoot = await Directory.systemTemp.createTemp('qy_ayah_sheet_inset');
    downloader = PackDownloader(
      db,
      libraryRootResolver: () async => tempRoot,
      fileDecoder: _syncDecode,
    );
  });

  tearDown(() async {
    await db.close();
    await tempRoot.delete(recursive: true);
  });

  testWidgets('modal sheet content clears the navigation bar', (tester) async {
    await tester.runAsync(() => _seedPacks(db, tempRoot));

    tester.view.physicalSize = const Size(400, kHeight);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: kInset);
    tester.view.viewPadding = const FakeViewPadding(bottom: kInset);
    addTearDown(tester.view.reset);

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
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => AyahSheet(
                  surahId: 1,
                  surahName: 'الفاتحة',
                  ayah: 1,
                  downloader: downloader,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    final pane = tester.getRect(find.byType(ListView));
    expect(pane.bottom, lessThanOrEqualTo(kHeight - kInset));
  });
}
