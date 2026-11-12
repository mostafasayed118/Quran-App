import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/settings_store.dart';

void main() {
  late AppDatabase db;
  late SettingsStore store;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.createSchemaForSeeding();
    store = SettingsStore(db);
  });

  tearDown(() => db.close());

  test('an unwritten key reads as null', () async {
    expect(await store.read('missing'), isNull);
  });

  test('write then read round-trips, and a second write replaces', () async {
    await store.write('theme', 'dark');
    expect(await store.read('theme'), 'dark');

    await store.write('theme', 'light');
    expect(await store.read('theme'), 'light');
  });

  test('readAll returns only the keys that exist', () async {
    await store.writeAll(<String, String>{'a': '1', 'b': '2'});

    expect(await store.readAll(['a', 'b', 'c']), {'a': '1', 'b': '2'});
  });

  test('readAll with no keys never touches the database', () async {
    expect(await store.readAll(const <String>[]), isEmpty);
  });

  test('remove deletes one key, leaves the rest, and no-ops when absent',
      () async {
    await store.writeAll(<String, String>{'keep': 'yes', 'drop': 'no'});

    await store.remove('drop');
    expect(await store.read('drop'), isNull);
    expect(await store.read('keep'), 'yes');

    await store.remove('drop');
  });

  test('writeAll lands every row in one batch', () async {
    await store.writeAll(<String, String>{
      for (var i = 0; i < 12; i++) 'k$i': '$i',
    });

    final values = await store.readAll(<String>[
      for (var i = 0; i < 12; i++) 'k$i',
    ]);
    expect(values, hasLength(12));
  });
}
