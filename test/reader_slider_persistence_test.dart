// Issue 5 (audit Top 5): dragging the reader font/line-height sliders previews
// immediately but writes settings only once, when the drag ends.
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_source.dart';
import 'package:quran_yahdi/features/quran/data/last_read_source.dart';
import 'package:quran_yahdi/features/quran/data/reader_layout_source.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_source.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';

class _Ayahs implements AyahSource {
  @override
  Future<List<Ayah>> surahAyahs(int surahId) async => const [
    Ayah(
      id: 1,
      surahId: 1,
      numberInSurah: 1,
      juz: 1,
      page: 1,
      textUthmani: 'بسم الله',
      textImlaei: 'بسم الله',
      sajda: false,
    ),
  ];

  @override
  Future<Surah?> surahById(int surahId) async => null;

  @override
  Stream<Set<int>> watchBookmarkedIds() => Stream.value(const <int>{});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LastRead implements LastReadSource {
  @override
  Future<int?> loadAyahId() async => null;

  @override
  Future<void> saveAyahId(int ayahId) async {}
}

class _CountingSettings implements ReaderSettingsSource, ReaderLayoutSource {
  double scale = 1;
  double lineHeight = ReaderLayoutSource.defaultLineHeight;
  final List<double> fontWrites = <double>[];
  final List<double> lineWrites = <double>[];

  @override
  Future<double> loadFontScale() async => scale;

  @override
  Future<void> saveFontScale(double value) async {
    fontWrites.add(value);
    scale = value;
  }

  @override
  Future<double> loadLineHeight() async => lineHeight;

  @override
  Future<void> saveLineHeight(double value) async {
    lineWrites.add(value);
    lineHeight = value;
  }
}

void main() {
  test(
    'font drag previews without writes, then persists once on end',
    () async {
      final settings = _CountingSettings();
      final cubit = ReaderCubit(
        ayahRepository: _Ayahs(),
        lastReadRepository: _LastRead(),
        surahId: 1,
        initialAyah: 1,
        settings: settings,
      );
      addTearDown(cubit.close);
      await cubit.start();

      await cubit.previewFontScale(1.2);
      await cubit.previewFontScale(1.5);
      expect((cubit.state as ReaderReady).fontScale, 1.5);
      expect(settings.fontWrites, isEmpty, reason: 'no write during the drag');

      await cubit.commitFontScale();
      expect(settings.fontWrites, [1.5]);
      expect(settings.scale, 1.5);
    },
  );

  test(
    'line-height drag previews without writes, then persists once',
    () async {
      final settings = _CountingSettings();
      final cubit = ReaderCubit(
        ayahRepository: _Ayahs(),
        lastReadRepository: _LastRead(),
        surahId: 1,
        initialAyah: 1,
        layout: settings,
      );
      addTearDown(cubit.close);
      await cubit.start();

      await cubit.previewLineHeight(2.2);
      await cubit.previewLineHeight(2.6);
      expect((cubit.state as ReaderReady).lineHeight, 2.6);
      expect(settings.lineWrites, isEmpty, reason: 'no write during the drag');

      await cubit.commitLineHeight();
      expect(settings.lineWrites, [2.6]);
      expect(settings.lineHeight, 2.6);
    },
  );

  test('the committed value is the clamped final preview', () async {
    final settings = _CountingSettings();
    final cubit = ReaderCubit(
      ayahRepository: _Ayahs(),
      lastReadRepository: _LastRead(),
      surahId: 1,
      initialAyah: 1,
      settings: settings,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await cubit.previewFontScale(3);
    await cubit.commitFontScale();
    expect(settings.fontWrites, [2.0]);
    expect((cubit.state as ReaderReady).fontScale, 2.0);
  });
}
