import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/features/duas/data/dua_repository.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_cubit.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_state.dart';

class _NoAyahs implements AyahLookup {
  @override
  Future<Ayah?> ayahById(int ayahId) async => null;

  @override
  Future<List<Ayah>> ayahsForRange(
          int surahId, int fromAyah, int toAyah) async =>
      const <Ayah>[];

  @override
  Future<Surah?> surahById(int surahId) async => null;
}

DuaRepository _duas() => DuaRepository(
    loader: () async => [
          {
            'id': 'd1',
            'categoryAr': 'المنزل',
            'text': 'دعاء المنزل',
          },
        ]);

void main() {
  test('a stale ruqyah load cannot flip a newer duas intent', () async {
    final gate = Completer<void>();
    final cubit = DuasCubit(
      duas: _duas(),
      ruqyah: RuqyahRepository(loader: () async {
        await gate.future;
        return [
          {'id': 'r1', 'kind': 'dhikr', 'text': 'رقية'},
        ];
      }),
      ayahs: _NoAyahs(),
    );
    addTearDown(cubit.close);

    await cubit.showDuas();
    expect(cubit.state, isA<DuasInView>());

    final staleRuqyah = cubit.showRuqyah();
    await pumpEventQueue();
    expect(cubit.state, isA<DuasLoading>());

    await cubit.showDuas();
    expect(cubit.state, isA<DuasInView>());

    gate.complete();
    await staleRuqyah;

    expect(
      cubit.state,
      isA<DuasInView>(),
      reason: 'the stale ruqyah load must not flip the visible tab',
    );
  });

  test('a stale ruqyah failure cannot replace a newer duas view', () async {
    final gate = Completer<void>();
    final cubit = DuasCubit(
      duas: _duas(),
      ruqyah: RuqyahRepository(loader: () async {
        await gate.future;
        throw StateError('ruqyah down');
      }),
      ayahs: _NoAyahs(),
    );
    addTearDown(cubit.close);

    await cubit.showDuas();
    final staleRuqyah = cubit.showRuqyah();
    await cubit.showDuas();
    expect(cubit.state, isA<DuasInView>());

    gate.complete();
    await staleRuqyah;

    expect(
      cubit.state,
      isA<DuasInView>(),
      reason: 'the stale failure must not replace the newer intent',
    );
  });
}
