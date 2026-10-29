import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/hadith/hadith_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/hadith/hadith_state.dart';

import 'support/test_db.dart';

class GatedHadithDownloader extends PackDownloader {
  GatedHadithDownloader(super.db);

  final Completer<void> pageGate = Completer<void>();
  int secondPageLoads = 0;

  @override
  Future<List<InstalledPack>> installedPacks() async => <InstalledPack>[];

  @override
  Future<(List<(int, String)>, bool)> hadithPage(
      String packId, int offset, int limit) async {
    if (offset == 0) {
      return (<(int, String)>[(1, 'first')], true);
    }
    secondPageLoads++;
    await pageGate.future;
    return (<(int, String)>[(11, 'second')], false);
  }
}

void main() {
  test('two rapid next() calls load only one page', () async {
    final downloader = GatedHadithDownloader(newTestDb());
    final cubit = HadithCubit(downloader: downloader, packId: 'pack');

    await cubit.start();
    final initial = cubit.state as HadithReady;
    expect(initial.offset, 0);
    expect(initial.hasMore, isTrue);

    final first = cubit.next();
    final second = cubit.next();
    await Future<void>.delayed(Duration.zero);
    expect(downloader.secondPageLoads, 1);

    downloader.pageGate.complete();
    await first;
    await second;

    final ready = cubit.state as HadithReady;
    expect(ready.offset, 10);
    expect(ready.items.single.$1, 11);
    expect(downloader.secondPageLoads, 1);

    await cubit.close();
  });
}
