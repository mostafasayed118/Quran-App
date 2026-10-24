import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/ayah_sheet/ayah_sheet_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/ayah_sheet/ayah_sheet_state.dart';

Future<dynamic> _syncDecode(String path) async =>
    jsonDecode(File(path).readAsStringSync());

class _OneCorruptPackDownloader extends PackDownloader {
  _OneCorruptPackDownloader(
    super.db, {
    required this.corruptPackId,
    required super.libraryRootResolver,
    required super.fileDecoder,
  });

  final String corruptPackId;

  @override
  Future<String?> tafsirFor(String packId, int surah, int ayah) {
    if (packId == corruptPackId) {
      return Future<String?>.error(StateError('corrupt pack'));
    }
    return super.tafsirFor(packId, surah, ayah);
  }
}

void main() {
  test('one unreadable pack does not hide the healthy tafsir entry', () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final tempRoot =
        await Directory.systemTemp.createTemp('qy_ayah_partial_test');
    addTearDown(() => tempRoot.delete(recursive: true));

    final libraryDir = Directory('${tempRoot.path}/library')
      ..createSync(recursive: true);
    File('test/fixtures/tafsir_wrapper_sample.json')
        .copySync('${libraryDir.path}/ar-tafsir-muyassar.json');
    await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
          packId: 'ar-tafsir-muyassar',
          kind: 'tafsir',
          language: 'ar',
          title: 'التفسير الميسر',
          sizeMb: 0.2,
          version: 'v1.2.2',
        ));
    await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
          packId: 'broken-tafsir',
          kind: 'tafsir',
          language: 'ar',
          title: 'تفسير تالف',
          sizeMb: 0.1,
          version: '1',
        ));

    final cubit = AyahSheetCubit(
      downloader: _OneCorruptPackDownloader(
        db,
        corruptPackId: 'broken-tafsir',
        libraryRootResolver: () async => tempRoot,
        fileDecoder: _syncDecode,
      ),
      surah: 1,
      ayah: 1,
    );
    addTearDown(cubit.close);

    final ready = await cubit.stream.firstWhere((s) => s is AyahSheetReady)
        as AyahSheetReady;

    expect(ready.tafsirEntries, hasLength(1));
    expect(ready.tafsirEntries.single.title, 'التفسير الميسر');
    expect(ready.tafsirEntries.single.text, contains('سميت الفاتحة'));
    expect(ready.translationEntries, isEmpty);
  });
}
