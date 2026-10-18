import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/download_limits.dart';

void main() {
  group('guardedByteCap', () {
    test('audio parity rows (ceiling = 64 MiB)', () {
      expect(guardedByteCap(0, ceiling: 64 << 20), 64 << 20);
      expect(guardedByteCap(1000, ceiling: 64 << 20), 1000 * 2 + 65536);
      expect(guardedByteCap(1 << 30, ceiling: 64 << 20), 64 << 20);
    });

    test('pack rows (no ceiling)', () {
      expect(guardedByteCap(0), 65536);
      expect(guardedByteCap(1000), 1000 * 2 + 65536);
      expect(guardedByteCap(1 << 30), (1 << 30) * 2 + 65536);
    });

    test('declared <= 0 rows fall back to the ceiling or the bare slack', () {
      expect(guardedByteCap(-5), 65536);
      expect(guardedByteCap(0, ceiling: 64 << 20), 64 << 20);
      expect(guardedByteCap(-5, ceiling: 64 << 20), 64 << 20);
    });

    test('a declared-derived cap under the ceiling stays uncapped', () {
      expect(guardedByteCap(4096, ceiling: 64 << 20), 4096 * 2 + 65536);
      expect(guardedByteCap(4096), 4096 * 2 + 65536);
    });
  });
}
