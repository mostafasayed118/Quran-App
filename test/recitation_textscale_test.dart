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
import 'package:quran_yahdi/features/recitation/presentation/playback/mini_player_bar.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciter_surahs/reciter_surahs_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciter_surahs/reciter_surahs_screen.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

class _StaticReciterRepository extends ReciterRepository {
  _StaticReciterRepository(super.db, this._rows);

  final List<ReciterRow> _rows;

  @override
  Stream<List<ReciterRow>> watchAll() => Stream.value(_rows);

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

class _StreamedPlaybackService implements PlaybackService {
  final playing = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();

  Object? loadError;

  @override
  Stream<bool> playingStream() => playing.stream;

  @override
  Stream<Duration> positionStream() => positionCtrl.stream;

  @override
  Stream<Duration?> durationStream() => durationCtrl.stream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {
    final error = loadError;
    if (error != null) throw error;
  }

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

  void seed(Map<String, DownloadItem> items) =>
      emit(DownloadsState(items: items));
}

ReciterRow _row({required String id, required String name}) => ReciterRow(
      id: id,
      reciterName: name,
      moshafName: 'مرتل',
      server: 'https://x/',
      surahList: '1',
      surahTotal: 114,
    );

const _playRow = ReciterRow(
  id: '51-53',
  reciterName: 'عبدالباسط عبدالصمد',
  moshafName: 'حفص عن عاصم - مرتل',
  server: 'https://x/',
  surahList: '1,2',
  surahTotal: 114,
);

/// A 360x780 logical phone at textScale 2.0 — the narrowest realistic case.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget _shell(Widget home) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2.0)),
        child: child!,
      ),
      home: home,
    );

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_scale_test');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  testWidgets('textScale 2.0: the reciters list survives the layout',
      (tester) async {
    _usePhoneViewport(tester);
    final repo = _StaticReciterRepository(db, [
      _row(id: '51-53', name: 'عبدالباسط عبدالصمد'),
      _row(id: '55-55', name: 'ماهر المعيقلي'),
    ]);
    final cubit = RecitersCubit(repo: repo);
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(_shell(
      BlocProvider<RecitersCubit>.value(
        value: cubit,
        child: const RecitersScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('عبدالباسط عبدالصمد'), findsOneWidget);
    expect(find.text('مختارات'), findsOneWidget);
  });

  testWidgets(
      'textScale 2.0: reciter surah rows with download states survive the layout',
      (tester) async {
    _usePhoneViewport(tester);
    final repo = _StaticReciterRepository(db, const []);
    final downloads = _SeededDownloadsCubit(
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      reciters: repo,
    );
    addTearDown(downloads.close);
    final playback = PlaybackCubit(
      service: _StreamedPlaybackService(),
      reciters: repo,
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => true,
    );
    addTearDown(playback.close);
    final surahs = ReciterSurahsCubit(
      reciters: repo,
      downloads: downloads,
      rowId: '51-53',
    );
    addTearDown(surahs.close);
    await surahs.start();
    await tester.pumpWidget(_shell(MultiBlocProvider(
      providers: [
        BlocProvider<PlaybackCubit>.value(value: playback),
        BlocProvider<DownloadsCubit>.value(value: downloads),
        BlocProvider<ReciterSurahsCubit>.value(value: surahs),
      ],
      child: const ReciterSurahsScreen(),
    )));
    await tester.pumpAndSettle();

    downloads.seed({
      '51-53-1': const DownloadItem(
        status: DownloadStatus.downloading,
        received: 1572864, // 1.5 MiB
        total: 3145728, // 3.0 MiB
      ),
      '51-53-2': const DownloadItem(status: DownloadStatus.done),
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('١.٥ من ٣.٠ م.ب'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('textScale 2.0: the playing mini player survives the layout',
      (tester) async {
    _usePhoneViewport(tester);
    final fake = _StreamedPlaybackService();
    final cubit = PlaybackCubit(
      service: fake,
      reciters: _StaticReciterRepository(db, const []),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => true,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(_shell(Scaffold(
      bottomSheet: BlocProvider<PlaybackCubit>.value(
        value: cubit,
        child: const MiniPlayerBar(),
      ),
    )));
    await tester.pumpAndSettle();

    await cubit.playSurah(_playRow, 1);
    fake.durationCtrl.add(const Duration(minutes: 6));
    fake.positionCtrl.add(Duration.zero);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('عبدالباسط عبدالصمد'), findsOneWidget);
    expect(find.text('سورة ١'), findsOneWidget);
  });

  testWidgets('textScale 2.0: the failed mini player strip survives the layout',
      (tester) async {
    _usePhoneViewport(tester);
    final fake = _StreamedPlaybackService()..loadError = StateError('x');
    final cubit = PlaybackCubit(
      service: fake,
      reciters: _StaticReciterRepository(db, const []),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => true,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(_shell(Scaffold(
      bottomSheet: BlocProvider<PlaybackCubit>.value(
        value: cubit,
        child: const MiniPlayerBar(),
      ),
    )));
    await tester.pumpAndSettle();

    await cubit.playSurah(_playRow, 1);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('تعذّر تشغيل التلاوة'), findsOneWidget);
  });
}
