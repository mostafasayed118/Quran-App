import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/pack_reader.dart';

/// Background-trim contract: the decoded projection cache must expose its
/// retained size and drop everything on demand, so the app can release the
/// primed index when it is backgrounded (the next read re-decodes from disk).
void main() {
  test('trim drops the primed cache', () {
    final reader = PackReader(packPath: (packId) async => null);
    reader.primeAyahIndex('p', {1: 'x'});
    expect(reader.cachedBytes, greaterThan(0));
    reader.trim();
    expect(reader.cachedBytes, 0);
  });
}
