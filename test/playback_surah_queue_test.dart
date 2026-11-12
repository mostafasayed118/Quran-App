import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_mapping.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

import 'support/fake_playback_service.dart';
import 'support/test_db.dart';

int? _number(PlaybackState state) => switch (state) {
      PlaybackPlaying(:final surahNumber) => surahNumber,
      PlaybackPaused(:final surahNumber) => surahNumber,
      PlaybackLoading(:final surahNumber) => surahNumber,
      _ => null,
    };

String? _name(PlaybackState state) => switch (state) {
      PlaybackPlaying(:final surahName) => surahName,
      PlaybackPaused(:final surahName) => surahName,
      PlaybackLoading(:final surahName) => surahName,
      _ => null,
    };

void main() {
  test('next/previous walk the reciter surah list, not 1..114', () async {
    final db = newTestDb();
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'قارئ',
            moshafName: 'حفص',
            server: 'https://server.example/mp3',
            surahList: '1,3,7',
            surahTotal: 3,
          ),
        );
    for (final (id, name) in [
      (1, 'الفاتحة'),
      (3, 'آل عمران'),
      (7, 'الأعراف')
    ]) {
      await db.into(db.surahs).insert(SurahsCompanion.insert(
            id: Value(id),
            nameAr: name,
            nameEn: name,
            revelationType: 'makkah',
            ayahCount: 7,
            pagesStart: 1,
            pagesEnd: 1,
          ));
    }
    final row = (await ReciterRepository(db).byId('51-53'))!;
    final cubit = PlaybackCubit(
      service: FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(
        db,
        audioRootResolver: () async => Directory.systemTemp,
      ),
      surahNames: ReciterRepository(db),
    );
    addTearDown(cubit.close);

    await cubit.playReciter(row.toInfo(), 1);
    expect(_number(cubit.state), 1);
    expect(_name(cubit.state), 'الفاتحة');
    expect(cubit.hasNextSurah, isTrue);
    expect(cubit.hasPreviousSurah, isFalse);

    await cubit.nextSurah();
    expect(_number(cubit.state), 3,
        reason: 'surah 2 is not in this reciter\'s list');
    expect(_name(cubit.state), 'آل عمران');

    await cubit.nextSurah();
    expect(_number(cubit.state), 7);
    expect(cubit.hasNextSurah, isFalse);

    await cubit.previousSurah();
    expect(_number(cubit.state), 3);
    expect(cubit.hasPreviousSurah, isTrue);
  });

  test('an empty surah list keeps the 1..114 fallback', () async {
    final db = newTestDb();
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'قارئ',
            moshafName: 'حفص',
            server: 'https://server.example/mp3',
            surahList: '',
            surahTotal: 114,
          ),
        );
    final row = (await ReciterRepository(db).byId('51-53'))!;
    final cubit = PlaybackCubit(
      service: FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(
        db,
        audioRootResolver: () async => Directory.systemTemp,
      ),
    );
    addTearDown(cubit.close);

    await cubit.playReciter(row.toInfo(), 1);
    await cubit.nextSurah();

    expect(_number(cubit.state), 2);
  });
}
