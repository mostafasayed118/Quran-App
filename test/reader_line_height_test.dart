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
  Future<Surah?> surahById(int surahId) async => const Surah(
        id: 1,
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatiha',
        revelationType: 'makki',
        ayahCount: 7,
        pagesStart: 1,
        pagesEnd: 1,
      );

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

class _Settings implements ReaderSettingsSource, ReaderLayoutSource {
  double scale = 1;
  double lineHeight = ReaderLayoutSource.defaultLineHeight;

  @override
  Future<double> loadFontScale() async => scale;

  @override
  Future<void> saveFontScale(double value) async {
    scale = value;
  }

  @override
  Future<double> loadLineHeight() async => lineHeight;

  @override
  Future<void> saveLineHeight(double value) async {
    lineHeight = value;
  }
}

void main() {
  test('the reader loads and clamps the line height', () async {
    final settings = _Settings()..lineHeight = 2.5;
    final cubit = ReaderCubit(
      ayahRepository: _Ayahs(),
      lastReadRepository: _LastRead(),
      surahId: 1,
      initialAyah: 1,
      layout: settings,
    );
    addTearDown(cubit.close);

    await cubit.start();
    expect(cubit.state, isA<ReaderReady>());
    expect((cubit.state as ReaderReady).lineHeight, 2.5);

    await cubit.setLineHeight(2.8);
    expect((cubit.state as ReaderReady).lineHeight, 2.8);
    expect(settings.lineHeight, 2.8);

    await cubit.setLineHeight(0.5);
    expect((cubit.state as ReaderReady).lineHeight,
        ReaderLayoutSource.minLineHeight);
    expect(settings.lineHeight, ReaderLayoutSource.minLineHeight);

    await cubit.setLineHeight(9);
    expect((cubit.state as ReaderReady).lineHeight,
        ReaderLayoutSource.maxLineHeight);
    expect(settings.lineHeight, ReaderLayoutSource.maxLineHeight);
  });

  test('a malformed stored line height falls back to the default', () async {
    final cubit = ReaderCubit(
      ayahRepository: _Ayahs(),
      lastReadRepository: _LastRead(),
      surahId: 1,
      initialAyah: 1,
      layout: _ThrowingLayout(),
    );
    addTearDown(cubit.close);

    await cubit.start();
    expect((cubit.state as ReaderReady).lineHeight,
        ReaderLayoutSource.defaultLineHeight);
  });
}

class _ThrowingLayout implements ReaderLayoutSource {
  @override
  Future<double> loadLineHeight() async => throw StateError('corrupt row');

  @override
  Future<void> saveLineHeight(double lineHeight) async {}
}
