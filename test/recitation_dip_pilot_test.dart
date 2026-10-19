import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_source.dart';
import 'package:quran_yahdi/features/recitation/domain/reciter_info.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_state.dart';

/// Pure in-memory [ReciterSource]: no `AppDatabase`, no drift runtime — the
/// DIP rollout's pole proof that the reciters list depends on the seam alone.
class _InMemoryReciterSource implements ReciterSource {
  _InMemoryReciterSource(this.rows);

  final List<ReciterRow> rows;

  @override
  Future<void> refreshFromApi() async {}

  @override
  Stream<List<ReciterRow>> watchAll() => Stream.value(rows);

  @override
  Future<ReciterRow?> byId(String rowId) async {
    for (final row in rows) {
      if (row.id == rowId) return row;
    }
    return null;
  }

  @override
  Future<void> selectMoshaf(String rowId) async {}

  @override
  Future<String?> loadSelectedMoshaf() async => null;

  @override
  Future<Map<int, String>> surahNamesFor(List<int> surahIds) async => {};

  @override
  Future<Map<int, String>> ayahTeasersFor(List<int> surahIds) async => {};
}

const _featured = ReciterRow(
  id: '51-53',
  reciterName: 'عبدالباسط عبدالصمد',
  moshafName: 'حفص عن عاصم - مرتل',
  server: 'https://server.mp3quran.net/bsit',
  surahList: '1,2',
  surahTotal: 114,
);

const _other = ReciterRow(
  id: '55-55',
  reciterName: 'تجربة أحمد',
  moshafName: 'مرتل',
  server: 'https://x/',
  surahList: '1',
  surahTotal: 114,
);

void main() {
  test('reciters ready carries mapped ReciterInfos from a pure seam fake',
      () async {
    final cubit =
        RecitersCubit(repo: _InMemoryReciterSource(const [_other, _featured]));
    addTearDown(cubit.close);

    final ready = await cubit.stream.firstWhere((s) => s is RecitersReady)
        as RecitersReady;

    expect(ready.reciters, everyElement(isA<ReciterInfo>()));
    expect(ready.reciters.map((r) => r.reciterName).toList(),
        ['عبدالباسط عبدالصمد', 'تجربة أحمد'],
        reason: 'featured rows sort first');
  });

  test('setQuery filters the entity list in place', () async {
    final cubit =
        RecitersCubit(repo: _InMemoryReciterSource(const [_other, _featured]));
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => s is RecitersReady);

    cubit.setQuery('أحمد');

    final ready = cubit.state as RecitersReady;
    expect(ready.query, 'أحمد');
    expect(ready.reciters, hasLength(1));
    expect(ready.reciters.single.reciterName, 'تجربة أحمد');
    expect(ready.reciters.single, isA<ReciterInfo>());
  });
}
