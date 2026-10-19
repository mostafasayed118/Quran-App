import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/mini_player_bar.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

class _FailingPlaybackService implements PlaybackService {
  _FailingPlaybackService({this.loadError});

  final Object? loadError;

  @override
  Stream<bool> playingStream() => const Stream<bool>.empty();

  @override
  Stream<Duration> positionStream() => const Stream<Duration>.empty();

  @override
  Stream<Duration?> durationStream() => const Stream<Duration?>.empty();

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

/// Empty catalog with a plain (non-drift-watch) stream: drift's watch streams
/// never emit under the widget tester's fake clock (frozen-test discipline).
class _EmptyCatalogRepository extends ReciterRepository {
  _EmptyCatalogRepository(super.db);

  @override
  Stream<List<ReciterRow>> watchAll() => Stream.value(const <ReciterRow>[]);
}

const _row = ReciterRow(
  id: '51-53',
  reciterName: 'عبدالباسط عبدالصمد',
  moshafName: 'حفص مرتل',
  server: 'https://server.example/mp3',
  surahList: '1,2',
  surahTotal: 114,
);

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_fail_copy_test');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  PlaybackCubit buildCubit({
    required bool backgroundActive,
    Object? error,
    ReciterRepository? reciters,
  }) =>
      PlaybackCubit(
        service: _FailingPlaybackService(loadError: error),
        reciters: reciters ?? ReciterRepository(db),
        downloader:
            AudioDownloader(db, audioRootResolver: () async => tempRoot),
        backgroundActive: () => backgroundActive,
      );

  Future<void> pumpBar(WidgetTester tester, PlaybackCubit cubit) async {
    addTearDown(cubit.close);
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<PlaybackCubit>.value(value: cubit),
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
        home: const Scaffold(bottomSheet: MiniPlayerBar()),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a network failure keeps the playback wording', (tester) async {
    final cubit = buildCubit(backgroundActive: true, error: StateError('x'));
    await cubit.playSurah(_row, 1);

    await pumpBar(tester, cubit);

    expect(find.text('تعذّر تشغيل التلاوة'), findsOneWidget);
  });

  testWidgets(
      'a background-inactive failure announces the missing background audio',
      (tester) async {
    final cubit = buildCubit(backgroundActive: false, error: StateError('x'));
    await cubit.playSurah(_row, 1);

    await pumpBar(tester, cubit);

    expect(find.text('تعذّر تشغيل التلاوة — الصوت في الخلفية غير متاح'),
        findsOneWidget);
    expect(find.text('تعذّر تشغيل التلاوة'), findsNothing,
        reason: 'the bare network copy must not stand in for the truthful one');
  });

  testWidgets(
      'a no-reciters failure speaks playback wording, not the index hint',
      (tester) async {
    final cubit = buildCubit(
      backgroundActive: true,
      reciters: _EmptyCatalogRepository(db),
    );
    await cubit.playDefaultForSurah(1);

    await pumpBar(tester, cubit);

    expect(find.text('تعذّر التشغيل — حمّل فهرس القرّاء من الإنترنت'),
        findsOneWidget);
    expect(find.text('حمّل فهرس القرّاء من الإنترنت'), findsNothing,
        reason: 'the bare index hint must not stand in for playback wording');
  });
}
