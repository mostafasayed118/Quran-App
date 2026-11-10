import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/update/data/version_ack_store.dart';

import 'support/test_db.dart';

void main() {
  test('the ack store round-trips through the settings table', () async {
    final db = newTestDb();
    final store = DriftVersionAckStore(db);

    expect(await store.read(), isNull);

    await store.write('9.9.9');
    expect(await store.read(), '9.9.9');

    await store.write('10.0.0');
    expect(await store.read(), '10.0.0');
  });
}
