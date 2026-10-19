import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_mapping.dart';
import 'package:quran_yahdi/features/recitation/domain/reciter_info.dart';

void main() {
  test('toInfo round-trips every carried field of the row', () {
    const row = ReciterRow(
      id: '51-53',
      reciterName: 'عبدالباسط عبدالصمد',
      moshafName: 'حفص عن عاصم - مرتل',
      server: 'https://server.mp3quran.net/bsit',
      surahList: '1,2,3',
      surahTotal: 114,
    );

    final info = row.toInfo();

    expect(info, isA<ReciterInfo>());
    expect(info.id, row.id);
    expect(info.reciterName, row.reciterName);
    expect(info.moshafName, row.moshafName);
    expect(info.server, row.server);
    expect(info.surahList, row.surahList);
    expect(info.surahTotal, row.surahTotal);
  });

  test('isFeaturedReciterInfo follows the pinned featured ids', () {
    const featured = ReciterInfo(
      id: '51-53',
      reciterName: 'عبدالباسط عبدالصمد',
      moshafName: 'حفص عن عاصم - مرتل',
      server: 'https://server.mp3quran.net/bsit',
      surahList: '1',
      surahTotal: 114,
    );
    const other = ReciterInfo(
      id: '55-55',
      reciterName: 'تجربة أحمد',
      moshafName: 'مرتل',
      server: 'https://x/',
      surahList: '1',
      surahTotal: 114,
    );
    const malformed = ReciterInfo(
      id: 'not-numeric',
      reciterName: 'بدون معرّف',
      moshafName: 'مرتل',
      server: 'https://x/',
      surahList: '1',
      surahTotal: 1,
    );

    expect(isFeaturedReciterInfo(featured), isTrue);
    expect(isFeaturedReciterInfo(other), isFalse);
    expect(isFeaturedReciterInfo(malformed), isFalse);
  });
}
