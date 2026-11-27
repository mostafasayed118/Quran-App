import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/feelings/data/feelings_repository.dart';
import 'package:quran_yahdi/features/feelings/domain/feeling.dart';
import 'package:quran_yahdi/features/feelings/presentation/feelings_cubit.dart';
import 'package:quran_yahdi/features/feelings/presentation/verse_detail_screen.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/uthmani_text_source.dart';

import '../../support/host.dart';

class _StubUthmani implements UthmaniTextSource {
  @override
  Future<Map<int, String>> forSurah(int surahId) async => {};

  @override
  Future<String?> forAyah(int surahId, int ayah) async =>
      (await forSurah(surahId))[ayah];
}

class _SpyRepo extends FeelingsRepository {
  _SpyRepo(AppDatabase db) : super(db, _StubUthmani(), AyahRepository(db));

  @override
  Future<FeelingVerseView> load(FeelingKey feeling, FeelingVerse verse) async {
    return FeelingVerseView(
      feeling: feeling,
      verse: verse,
      fullText: 'آية',
      surahName: 'الرعد',
      juz: 13,
      ayahId: 1,
    );
  }

  @override
  Future<bool> isSaved(int ayahId) async => false;
}

void main() {
  testWidgets('tapping Listen reaches the injected playSurah callback', (
    tester,
  ) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final played = <(int, String)>[];
    final cubit = VerseDetailCubit(
      _SpyRepo(db),
      FeelingKey.qalaq,
      13,
      28,
      playSurah: (surah, name) async => played.add((surah, name)),
    );
    await cubit.start();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      appShell(
        home: const VerseDetailScreen(),
        wrap: (app) =>
            BlocProvider<VerseDetailCubit>.value(value: cubit, child: app),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.headphones));
    await tester.pump();

    expect(played, [(13, 'الرعد')]);
  });
}
