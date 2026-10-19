import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/duas/data/dua_repository.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_cubit.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_state.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';

import 'support/test_db.dart';

class _CountingAyahs extends AyahRepository {
  _CountingAyahs(super.db);

  final rangeCalls = <int>[];
  int surahCalls = 0;

  @override
  Future<List<Ayah>> ayahsForRange(
      int surahId, int fromAyah, int toAyah) async {
    rangeCalls.add(surahId);
    return const <Ayah>[];
  }

  @override
  Future<Surah?> surahById(int surahId) async {
    surahCalls++;
    return null;
  }
}

/// Entry 1's range read blocks until the test releases it; entry 2 resolves
/// immediately. Entry 2 being invoked while entry 1 is pending proves the
/// resolutions run concurrently.
class _GatedAyahs extends _CountingAyahs {
  _GatedAyahs(super.db);

  final gate = Completer<List<Ayah>>();

  @override
  Future<List<Ayah>> ayahsForRange(int surahId, int fromAyah, int toAyah) {
    rangeCalls.add(surahId);
    return surahId == 1 ? gate.future : Future.value(const <Ayah>[]);
  }
}

class _CountingRuqyah extends RuqyahRepository {
  _CountingRuqyah({required super.loader});

  int entryCalls = 0;

  @override
  Future<List<RuqyahEntry>> entries() {
    entryCalls++;
    return super.entries();
  }
}

Future<void> _pumpUntil(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition was not reached within 5s');
    }
    await Future<void>.delayed(Duration.zero);
  }
}

DuaRepository _duas() => DuaRepository(
      loader: () async => [
        {
          'id': 'a1',
          'categoryAr': 'المنزل',
          'categoryEn': 'Home',
          'text': 'بِسْمِ اللَّهِ وَلَجْنَا',
        },
      ],
    );

List<Map<String, dynamic>> _quranEntries() => [
      {'id': 'r1', 'kind': 'quran', 'surahId': 1, 'fromAyah': 1, 'toAyah': 2},
      {'id': 'r2', 'kind': 'quran', 'surahId': 2, 'fromAyah': 3, 'toAyah': 4},
    ];

void main() {
  test('a later entry resolves while an earlier one is still pending',
      () async {
    final db = newTestDb();
    final ayahs = _GatedAyahs(db);
    final cubit = DuasCubit(
      duas: _duas(),
      ruqyah: RuqyahRepository(loader: () async => _quranEntries()),
      ayahs: ayahs,
    );
    addTearDown(cubit.close);

    final resolution = cubit.showRuqyah();

    await _pumpUntil(() => ayahs.rangeCalls.length == 2);
    expect(ayahs.gate.isCompleted, isFalse,
        reason: 'the gate must still be pending for the proof to hold');
    expect(ayahs.rangeCalls, [1, 2],
        reason: 'entry 2 must be invoked although entry 1 is still pending');

    ayahs.gate.complete(const <Ayah>[]);
    await resolution;

    final resolved = (cubit.state as RuqyahInView).entries;
    expect([for (final entry in resolved) entry.id], ['r1', 'r2'],
        reason: 'Future.wait preserves the entry order');
    expect(resolved.first.citation, ' ١–٢');
    expect(resolved.last.citation, ' ٣–٤');
  });

  test('resolution keeps the serial call counts (one range + one surah each)',
      () async {
    final db = newTestDb();
    final ayahs = _CountingAyahs(db);
    final ruqyah = _CountingRuqyah(
        loader: () async => [
              ..._quranEntries(),
              {
                'id': 'r3',
                'kind': 'dhikr',
                'text': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ',
                'count': 3,
              },
            ]);
    final cubit = DuasCubit(duas: _duas(), ruqyah: ruqyah, ayahs: ayahs);
    addTearDown(cubit.close);

    await cubit.showRuqyah();

    expect(ayahs.rangeCalls, [1, 2]);
    expect(ayahs.surahCalls, 2);
    expect(ruqyah.entryCalls, 1);
    final resolved = (cubit.state as RuqyahInView).entries;
    expect([for (final entry in resolved) entry.id], ['r1', 'r2', 'r3']);
    expect(resolved.last.isQuran, isFalse);
    expect(resolved.last.count, 3);
  });
}
