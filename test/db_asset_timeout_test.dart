import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:quran_yahdi/core/db/connection.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('qy_asset_timeout_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));

  test('a worker asset read that never completes falls back to the UI isolate',
      () async {
    final target = File(p.join(tempDir.path, 'quran_yahdi.sqlite'));
    final never = Completer<Uint8List?>();

    await writeAssetOffUiIsolate(
      target,
      'assets/db/quran.sqlite',
      workerLoad: () => never.future,
      loadAsset: (_) async => ByteData.sublistView(bytes),
      timeout: const Duration(milliseconds: 50),
    );

    expect(target.existsSync(), isTrue);
    expect(await target.readAsBytes(), bytes);
    expect(File('${target.path}.part').existsSync(), isFalse);
  });

  test('a throwing worker asset read falls back to the UI isolate', () async {
    final target = File(p.join(tempDir.path, 'quran_yahdi.sqlite'));

    await writeAssetOffUiIsolate(
      target,
      'assets/db/quran.sqlite',
      workerLoad: () async => throw StateError('worker unavailable'),
      loadAsset: (_) async => ByteData.sublistView(bytes),
    );

    expect(await target.readAsBytes(), bytes);
  });

  test('an existing target never touches the worker', () async {
    final target = File(p.join(tempDir.path, 'quran_yahdi.sqlite'));
    await target.writeAsBytes(bytes);
    var workerCalls = 0;

    await writeAssetOffUiIsolate(
      target,
      'assets/db/quran.sqlite',
      workerLoad: () async {
        workerCalls++;
        return bytes;
      },
      loadAsset: (_) async => throw StateError('UI isolate must not run'),
    );

    expect(workerCalls, 0);
    expect(await target.readAsBytes(), bytes);
  });
}
