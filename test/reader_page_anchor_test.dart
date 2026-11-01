import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/quran/data/ayah_source.dart';
import 'package:quran_yahdi/features/quran/data/last_read_source.dart';
import 'package:quran_yahdi/features/quran/data/page_anchor_source.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';

class _NoAyahs implements AyahSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoLastRead implements LastReadSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Anchors implements PageAnchorSource {
  @override
  Future<({int surahId, int numberInSurah})?> anchorForPage(int page) async =>
      page == 604 ? (surahId: 112, numberInSurah: 1) : null;
}

void main() {
  test('the reader resolves a page through its optional anchor source',
      () async {
    final cubit = ReaderCubit(
      ayahRepository: _NoAyahs(),
      lastReadRepository: _NoLastRead(),
      surahId: 1,
      initialAyah: 1,
      pageAnchors: _Anchors(),
    );
    addTearDown(cubit.close);

    expect(await cubit.anchorForPage(604), (surahId: 112, numberInSurah: 1));
    expect(await cubit.anchorForPage(1), isNull);
  });
}
