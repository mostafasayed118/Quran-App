import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/download_status.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_state.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciter_surahs/reciter_surahs_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

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
  Future<Map<int, String>> ayahTeasersFor(List<int> surahIds) async => {};

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

class _SeededDownloadsCubit extends DownloadsCubit {
  _SeededDownloadsCubit({
    required super.downloader,
    required super.reciters,
  });

  final List<String> cancelled = <String>[];

  void seed(Map<String, DownloadItem> items) =>
      emit(DownloadsState(items: items));

  @override
  Future<void> cancelDownload(String rowId, int surahNumber) async {
    cancelled.add('$rowId-$surahNumber');
  }
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_dl_ui_test');
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

  Future<_SeededDownloadsCubit> pumpSurahsHost(WidgetTester tester) async {
    final repo = _StaticReciterRepository(db);
    final downloads = _SeededDownloadsCubit(
      downloader: AudioDownloader(
        db,
        audioRootResolver: () async => tempRoot,
      ),
      reciters: repo,
    );
    addTearDown(downloads.close);
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
    return downloads;
  }

  testWidgets('a queued row offers cancel and never the plain download icon',
      (tester) async {
    final downloads = await pumpSurahsHost(tester);

    downloads
        .seed({'51-53-1': const DownloadItem(status: DownloadStatus.queued)});
    await tester.pumpAndSettle();

    expect(find.byTooltip('إلغاء'), findsOneWidget);
    // Surah 2 stays on the plain download affordance.
    expect(find.byIcon(Icons.download), findsOneWidget);

    await tester.tap(find.byTooltip('إلغاء'));
    expect(downloads.cancelled, ['51-53-1']);
  });

  testWidgets('a downloading row shows the MB label and a cancel affordance',
      (tester) async {
    final downloads = await pumpSurahsHost(tester);

    downloads.seed({
      '51-53-1': const DownloadItem(
        status: DownloadStatus.downloading,
        received: 1572864, // 1.5 MiB
        total: 3145728, // 3.0 MiB
      ),
    });
    await tester.pumpAndSettle();

    expect(find.text('١.٥ من ٣.٠ م.ب'), findsOneWidget);
    await tester.tap(find.byTooltip('إلغاء'));
    expect(downloads.cancelled, ['51-53-1']);
  });

  testWidgets('an unknown total renders the received-only label',
      (tester) async {
    final downloads = await pumpSurahsHost(tester);

    downloads.seed({
      '51-53-1': const DownloadItem(
        status: DownloadStatus.downloading,
        received: 1048576, // 1.0 MiB
        total: 0,
      ),
    });
    // The unknown-total bar is indeterminate and animates forever:
    // pumpAndSettle would never settle, so pump twice by hand.
    await tester.pump();
    await tester.pump();

    expect(find.text('١.٠ م.ب'), findsOneWidget);
  });

  testWidgets('a failed row retries with the localized tooltip',
      (tester) async {
    final downloads = await pumpSurahsHost(tester);

    downloads
        .seed({'51-53-1': const DownloadItem(status: DownloadStatus.failed)});
    await tester.pumpAndSettle();

    expect(find.byTooltip('أعِد المحاولة'), findsOneWidget);
  });
}
