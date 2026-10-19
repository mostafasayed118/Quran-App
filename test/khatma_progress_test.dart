import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/tracker/data/khatma_progress.dart';

void main() {
  KhatmaProgress progress({required int page, int target = 604}) =>
      KhatmaProgress(
        pointerAyahId: 1,
        pointerPage: page,
        targetPages: target,
        readerSurahId: 1,
        readerAyahNumber: 1,
      );

  test('daily portions match the four offered paces', () {
    expect(KhatmaProgress.targetChoices, [604, 302, 201, 151]);
    expect(KhatmaProgress.dailyPagesFor(604), 20);
    expect(KhatmaProgress.dailyPagesFor(302), 10);
    expect(KhatmaProgress.dailyPagesFor(201), 7);
    expect(KhatmaProgress.dailyPagesFor(151), 5);
  });

  test('today range starts at the pointer page and spans the daily portion',
      () {
    final p = progress(page: 41, target: 302);
    expect(p.todayStartPage, 41);
    expect(p.todayEndPage, 50);
  });

  test('today range clamps to the last page near the end of the mushaf', () {
    final p = progress(page: 600);
    expect(p.todayEndPage, 604);
  });

  test('pages done counts everything before the pointer page', () {
    final p = progress(page: 101);
    expect(p.pagesDone, 100);
    expect(p.fraction, closeTo(100 / 604, 0.0001));
    expect(p.remainingPages, 504);
    expect(p.remainingDays, 26);
  });

  test('completion is the pointer reaching the last page', () {
    expect(progress(page: 603).completed, isFalse);
    expect(progress(page: 604).completed, isTrue);
  });

  test('day-one plan: nothing done, the full mushaf ahead', () {
    final p = progress(page: 1);
    expect(p.pagesDone, 0);
    expect(p.fraction, 0);
    expect(p.remainingPages, 604);
    expect(p.remainingDays, 31);
  });
}
