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
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

class _FakePlaybackService implements PlaybackService {
  // Sync broadcast controllers: their subscription-cancel futures complete
  // without scheduling, which the widget tester's fake clock cannot flush
  // for async controllers mid-`stopAndReset`.
  final playing = StreamController<bool>.broadcast(sync: true);
  final positionCtrl = StreamController<Duration>.broadcast(sync: true);
  final durationCtrl = StreamController<Duration?>.broadcast(sync: true);

  Object? loadError;
  int stopCount = 0;

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
  Future<void> stop() async => stopCount += 1;
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
    tempRoot = await Directory.systemTemp.createTemp('qy_stop_test');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  /// Built inside the test body on purpose: the playback service's stream
  /// controllers must live in the widget tester's fake-clock zone, or their
  /// subscription-cancel futures never complete during `stopAndReset`.
  ({_FakePlaybackService fake, PlaybackCubit cubit}) build(
      WidgetTester tester) {
    final fake = _FakePlaybackService();
    final cubit = PlaybackCubit(
      service: fake,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => true,
    );
    addTearDown(cubit.close);
    return (fake: fake, cubit: cubit);
  }

  Future<void> pumpBar(WidgetTester tester, PlaybackCubit cubit) async {
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

  testWidgets('the stop control uses the stop glyph and resets playback',
      (tester) async {
    final (:fake, :cubit) = build(tester);
    await pumpBar(tester, cubit);
    await cubit.playSurah(_row, 1);
    // Determinate progress: an unknown duration renders an indeterminate bar
    // that animates forever and would never let pumpAndSettle settle.
    fake.durationCtrl.add(const Duration(minutes: 6));
    fake.positionCtrl.add(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing,
        reason: 'close is the dismiss glyph, not stop');

    await tester.tap(find.byIcon(Icons.stop));
    // Subscription-cancel futures (inside stopAndReset) only complete on a
    // real event-loop turn; plain fake-clock pumps never resolve them.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(fake.stopCount, 1);
    expect(cubit.state, isA<PlaybackInitial>());
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('the failed strip dismiss carries the unified stop wording',
      (tester) async {
    final (:fake, :cubit) = build(tester);
    fake.loadError = StateError('boom');
    await pumpBar(tester, cubit);
    await cubit.playSurah(_row, 1);
    await tester.pumpAndSettle();

    expect(cubit.state, isA<PlaybackFailed>());
    expect(find.byTooltip('إيقاف'), findsOneWidget);
    expect(find.byTooltip('وقف'), findsNothing,
        reason: 'the dual stop wording must be gone');
  });
}
