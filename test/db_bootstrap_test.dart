import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/connection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('copyDbAssetIfAbsent keeps existing file, copies when absent', () async {
    final dir = await Directory.systemTemp.createTemp('qy_bootstrap');
    final target = File('${dir.path}${Platform.pathSeparator}seed.sqlite');
    await target.writeAsBytes([1, 2, 3]);

    Future<ByteData> loader(String key) async =>
        ByteData.sublistView(Uint8List.fromList([9, 8, 7]));

    await copyDbAssetIfAbsent(
        target: target, assetKey: 'assets/db/quran.sqlite', loadAsset: loader);
    expect(await target.readAsBytes(), [1, 2, 3],
        reason: 'existing file untouched');

    await target.delete();
    await copyDbAssetIfAbsent(
        target: target, assetKey: 'assets/db/quran.sqlite', loadAsset: loader);
    expect(await target.readAsBytes(), [9, 8, 7], reason: 'absent file copied');

    await dir.delete(recursive: true);
  });
}
