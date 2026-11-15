import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/connection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('copyDbAssetIfAbsent keeps existing file, copies when absent', () async {
    final dir = await Directory.systemTemp.createTemp('qy_bootstrap');
    final target = File('${dir.path}${Platform.pathSeparator}seed.sqlite');
    // An existing file is kept only when it is a SQLite database (the header
    // is the only check); this fixture carries the real 16-byte magic.
    const sqliteHeader = <int>[
      0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, //
      0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
    ];
    await target.writeAsBytes([...sqliteHeader, 1, 2, 3]);

    Future<ByteData> loader(String key) async =>
        ByteData.sublistView(Uint8List.fromList([9, 8, 7]));

    await copyDbAssetIfAbsent(
        target: target, assetKey: 'assets/db/quran.sqlite', loadAsset: loader);
    expect(await target.readAsBytes(), [...sqliteHeader, 1, 2, 3],
        reason: 'existing file untouched');

    await target.delete();
    await copyDbAssetIfAbsent(
        target: target, assetKey: 'assets/db/quran.sqlite', loadAsset: loader);
    expect(await target.readAsBytes(), [9, 8, 7], reason: 'absent file copied');

    await dir.delete(recursive: true);
  });
}
