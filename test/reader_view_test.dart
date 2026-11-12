import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/di/injector.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';

import 'support/fake_playback_service.dart';
import 'support/host.dart';
import 'support/test_db.dart';

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db);

  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});
}

Future<dynamic> _syncDecode(String path) async => null;

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_reader_view');
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'madinah',
          ayahCount: 1,
          pagesStart: 2,
          pagesEnd: 2,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(8),
          surahId: 2,
          numberInSurah: 1,
          juz: 1,
          page: 2,
          textUthmani: 'الم',
          textImlaei: 'الم',
        ));
  });

  tearDown(() async {
    await db.close();
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  testWidgets('ReaderScreen composes ReaderView and the five actions',
      (tester) async {
    await getIt.reset();
    getIt.registerLazySingleton<PackDownloader>(() => PackDownloader(
          db,
          libraryRootResolver: () async => tempRoot,
          fileDecoder: _syncDecode,
        ));
    addTearDown(getIt.reset);

    final cubit = ReaderCubit(
      ayahRepository: _TeardownSafeAyahRepository(db),
      lastReadRepository: LastReadRepository(db),
      surahId: 2,
      initialAyah: 0,
    );
    addTearDown(cubit.close);
    await cubit.start();

    final playback = PlaybackCubit(
      service: FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(
        db,
        audioRootResolver: () async => Directory.systemTemp,
      ),
    );
    addTearDown(playback.close);

    await tester.pumpWidget(appShell(
        home: MultiBlocProvider(
      providers: [
        BlocProvider<ReaderCubit>.value(value: cubit),
        BlocProvider<PlaybackCubit>.value(value: playback),
      ],
      child: const ReaderScreen(),
    )));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.byType(ReaderView), findsOneWidget);
    expect(find.byType(ReaderActions), findsOneWidget);
    expect(find.byTooltip('حجم الخط'), findsOneWidget);
    expect(find.text('الم'), findsOneWidget);
  });
}
