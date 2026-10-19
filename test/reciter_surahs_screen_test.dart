import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciter_surahs/reciter_surahs_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_surahs_test');
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'PLACEHOLDER',
            surahList: '1,2',
            surahTotal: 114,
          ),
        );
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
  });

  Future<void> pumpSurahsHost(
    WidgetTester tester,
    _StaticDownloadsCubit downloads,
  ) async {
    final repo = _StaticReciterRepository(db);
    final playbackCubit = PlaybackCubit(
      service: _FakePlaybackService(),
      reciters: repo,
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
    );
    addTearDown(playbackCubit.close);
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<PlaybackCubit>.value(value: playbackCubit),
        BlocProvider<DownloadsCubit>.value(value: downloads),
        BlocProvider<ReciterSurahsCubit>(
          create: (_) => ReciterSurahsCubit(
            reciters: repo,
            downloads: downloads,
            rowId: '51-53',
          ),
        ),
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
        home: const ReciterSurahsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('rows render surah names + opening ayah teasers', (tester) async {
    final downloads = _StaticDownloadsCubit(db, tempRoot);
    addTearDown(downloads.close);
    await pumpSurahsHost(tester, downloads);

    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('الم'), findsOneWidget);
    expect(find.text('ذلك الكتاب'), findsOneWidget);
  });

  testWidgets('tapping the download icon calls enqueue', (tester) async {
    final downloads = _StaticDownloadsCubit(db, tempRoot);
    addTearDown(downloads.close);
    await pumpSurahsHost(tester, downloads);

    await tester.tap(find.byIcon(Icons.download).first);
    await tester.pumpAndSettle();

    expect(downloads.enqueuedKey, '51-53-1');
  });

  testWidgets('done row exposes delete; confirm delegates to removeDone',
      (tester) async {
    final dir = Directory('${tempRoot.path}/audio/51-53')
      ..createSync(recursive: true);
    final file = File('${dir.path}/001.mp3')..writeAsBytesSync([1, 2, 3]);
    await db.into(db.downloads).insert(DownloadsCompanion.insert(
          reciterId: '51-53',
          surahId: 1,
          status: 'done',
          path: file.path,
          bytes: const Value(3),
        ));
    final downloads = _StaticDownloadsCubit(db, tempRoot);
    addTearDown(downloads.close);
    await pumpSurahsHost(tester, downloads);

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('حذف').last);
    await tester.pumpAndSettle();

    expect(downloads.removedKeys, contains('51-53-1'));
  });

  test('removeDone removes file + DB row and drops the state entry', () async {
    final dir = Directory('${tempRoot.path}/audio/51-53')
      ..createSync(recursive: true);
    final file = File('${dir.path}/001.mp3')..writeAsBytesSync([1, 2, 3]);
    await db.into(db.downloads).insert(DownloadsCompanion.insert(
          reciterId: '51-53',
          surahId: 1,
          status: 'done',
          path: file.path,
          bytes: const Value(3),
        ));
    final downloads = DownloadsCubit(
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      reciters: _StaticReciterRepository(db),
    );
    addTearDown(downloads.close);
    await downloads.refreshDone();
    expect(downloads.state.items.containsKey('51-53-1'), isTrue);

    await downloads.removeDone('51-53', 1);

    expect(file.existsSync(), isFalse);
    expect(await db.select(db.downloads).get(), isEmpty);
    expect(downloads.state.items.containsKey('51-53-1'), isFalse);
  });
}

class _StaticReciterRepository extends ReciterRepository {
  _StaticReciterRepository(super.db);

  @override
  Future<ReciterRow?> byId(String rowId) async => const ReciterRow(
        id: '51-53',
        reciterName: 'عبدالباسط عبدالصمد',
        moshafName: 'حفص عن عاصم - مرتل',
        server: 'PLACEHOLDER',
        surahList: '1,2',
        surahTotal: 114,
      );

  @override
  Future<Map<int, String>> surahNamesFor(List<int> surahIds) async =>
      {1: 'الفاتحة', 2: 'البقرة'};

  @override
  Future<Map<int, String>> ayahTeasersFor(List<int> surahIds) async =>
      {1: 'الم', 2: 'ذلك الكتاب'};

  @override
  Future<void> selectMoshaf(String rowId) async {}
}

class _FakePlaybackService implements PlaybackService {
  @override
  Stream<bool> playingStream() => const Stream<bool>.empty();

  @override
  Stream<Duration> positionStream() => const Stream<Duration>.empty();

  @override
  Stream<Duration?> durationStream() => const Stream<Duration?>.empty();

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}

class _StaticDownloadsCubit extends DownloadsCubit {
  _StaticDownloadsCubit(AppDatabase db, Directory tempRoot)
      : super(
          downloader: AudioDownloader(
            db,
            dio: Dio(),
            audioRootResolver: () async => tempRoot,
          ),
          reciters: _StaticReciterRepository(db),
        );

  String? enqueuedKey;
  final List<String> removedKeys = <String>[];

  @override
  Future<void> enqueue(String rowId, int surahNumber) async {
    enqueuedKey = '$rowId-$surahNumber';
  }

  @override
  Future<void> removeDone(String rowId, int surahNumber) async {
    removedKeys.add('$rowId-$surahNumber');
  }
}
