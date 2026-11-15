import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/connection.dart';

ByteData _bytes(List<int> values) =>
    ByteData.sublistView(Uint8List.fromList(values));

Future<ByteData> _asset(String _) async => _bytes(<int>[1, 2, 3, 4]);

Future<ByteData> _mustNotLoad(String _) async =>
    throw StateError('an existing valid database must not be replaced');

void main() {
  late Directory dir;
  late File target;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('qy_db_repair');
    target = File(p.join(dir.path, 'quran_yahdi.sqlite'));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('a missing target is written atomically and leaves no .part', () async {
    await copyDbAssetIfAbsent(
      target: target,
      assetKey: 'asset',
      loadAsset: _asset,
    );

    expect(await target.readAsBytes(), <int>[1, 2, 3, 4]);
    expect(File('${target.path}.part').existsSync(), isFalse,
        reason: 'a crashed write must never leave a half-written target');
  });

  test('a valid database with user rows is never touched', () async {
    final db = AppDatabase(NativeDatabase(target));
    await db.into(db.bookmarks).insert(
          BookmarksCompanion.insert(ayahId: 7),
        );
    await db.close();
    final before = await target.readAsBytes();

    await copyDbAssetIfAbsent(
      target: target,
      assetKey: 'asset',
      loadAsset: _mustNotLoad,
    );

    expect(await target.readAsBytes(), before);
    expect(
      dir.listSync().where((e) => e.path.contains('.corrupt-')),
      isEmpty,
      reason: 'user data must not be moved aside',
    );
  });

  test('a valid header with a truncated body is kept (decision)', () async {
    const sqliteHeader = <int>[
      0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, //
      0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
    ];
    // A real header with a body that is not a database: the shape a process
    // kill mid-write used to produce. The header check cannot tell it apart,
    // and the decision is to keep it (never destroy a possibly-populated file)
    // rather than run an integrity check on every boot.
    final truncated = <int>[...sqliteHeader, 0, 1, 2, 3, 4];
    await target.writeAsBytes(truncated);

    await copyDbAssetIfAbsent(
      target: target,
      assetKey: 'asset',
      loadAsset: _mustNotLoad,
    );

    expect(hasSqliteHeader(target), isTrue);
    expect(await target.readAsBytes(), truncated,
        reason: 'a valid header is kept as-is: no silent replacement');
    expect(
      dir.listSync().whereType<File>().where(
            (f) => f.path.contains('.corrupt-'),
          ),
      isEmpty,
      reason: 'a possibly-populated file is never moved aside automatically',
    );
  });

  test('a file that is not SQLite is moved aside and replaced', () async {
    await target.writeAsString('not a database');

    await copyDbAssetIfAbsent(
      target: target,
      assetKey: 'asset',
      loadAsset: _asset,
    );

    expect(await target.readAsBytes(), <int>[1, 2, 3, 4]);
    final asides = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('.corrupt-'))
        .toList();
    expect(asides, hasLength(1));
    expect(await asides.single.readAsString(), 'not a database',
        reason: 'the unusable file is preserved, not deleted');
    expect(p.basename(asides.single.path), contains('T'),
        reason: 'the aside name carries the moment it was moved');
  });

  test('an existing aside is never overwritten', () async {
    final original = File('${target.path}.corrupt-2026-11-15T10-00-00-000');
    await original.writeAsString('first');
    await target.writeAsString('second');

    final aside = await moveDbAside(target, now: DateTime(2026, 11, 15, 10));

    expect(aside.path, isNot(original.path));
    expect(await original.readAsString(), 'first');
    expect(await aside.readAsString(), 'second');
  });

  test('the worker path repairs a non-SQLite target too', () async {
    await target.writeAsString('garbage');

    await writeAssetOffUiIsolate(
      target,
      'asset',
      workerLoad: () async => Uint8List.fromList(<int>[9, 9, 9, 9]),
    );

    expect(await target.readAsBytes(), <int>[9, 9, 9, 9]);
    expect(
      dir.listSync().whereType<File>().where(
            (f) => f.path.contains('.corrupt-'),
          ),
      hasLength(1),
    );
  });
}
