import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const dbAssetKey = 'assets/db/quran.sqlite';

@visibleForTesting
Future<void> copyDbAssetIfAbsent({
  required File target,
  required String assetKey,
  required Future<ByteData> Function(String) loadAsset,
}) async {
  if (target.existsSync()) return;
  await target.parent.create(recursive: true);
  final data = await loadAsset(assetKey);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await target.writeAsBytes(bytes, flush: true);
}

Future<QueryExecutor> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'quran_yahdi.sqlite'));
  await copyDbAssetIfAbsent(
    target: file,
    assetKey: dbAssetKey,
    loadAsset: rootBundle.load,
  );
  return NativeDatabase.createInBackground(file);
}
