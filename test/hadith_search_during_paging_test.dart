import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/hadith/hadith_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/hadith/hadith_state.dart';

import 'support/test_db.dart';

class _GatedPageDownloader extends PackDownloader {
  _GatedPageDownloader(super.db);

  final Completer<void> pageGate = Completer<void>();

  @override
  Future<List<InstalledPack>> installedPacks() async => const <InstalledPack>[];

  @override
  Future<(List<(int, String)>, bool)> hadithPage(
    String packId,
    int offset,
    int limit,
  ) async {
    if (offset == 0) return (<(int, String)>[(1, 'first')], true);
    await pageGate.future;
    return (<(int, String)>[(11, 'second')], false);
  }

  @override
  Future<(List<(int, String)>, bool)> hadithSearch(
    String packId,
    String query, {
    int offset = 0,
    int limit = 20,
  }) async =>
      (<(int, String)>[(42, 'needle $query')], false);
}

void main() {
  test('a search issued while a page is loading still wins', () async {
    final downloader = _GatedPageDownloader(newTestDb());
    final cubit = HadithCubit(downloader: downloader, packId: 'pack');
    addTearDown(cubit.close);

    await cubit.start();
    final page = cubit.next();
    await Future<void>.delayed(Duration.zero);

    // Subscribe before the page gate opens: the queued search emits right
    // after the page load resolves.
    final searched = cubit.stream.firstWhere(
      (state) => state is HadithReady && state.query == 'needle',
    );
    await cubit.search('needle');

    downloader.pageGate.complete();
    await page;

    final ready = await searched as HadithReady;
    expect(ready.items.single.$1, 42);
    expect(ready.query, 'needle');
  });
}
