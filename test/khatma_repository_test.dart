import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tracker/data/khatma_repository.dart';

import 'support/test_db.dart';

AyahsCompanion _ayah(int id, {required int page, required int number}) =>
    AyahsCompanion.insert(
      id: Value(id),
      surahId: 1,
      numberInSurah: number,
      juz: 1,
      page: page,
      textUthmani: 'x',
      textImlaei: 'x',
    );

void main() {
  late AppDatabase db;
  late KhatmaRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = KhatmaRepository(db);
    await db.batch((b) => b.insertAll(db.ayahs, [
          _ayah(1, page: 1, number: 1),
          _ayah(2, page: 1, number: 2),
          _ayah(3, page: 2, number: 3),
          _ayah(8, page: 5, number: 4),
          _ayah(9, page: 6, number: 5),
          _ayah(90, page: 603, number: 6),
          _ayah(91, page: 604, number: 7),
          _ayah(6236, page: 604, number: 8),
        ]));
  });

  test('no plan until one starts', () async {
    expect(await repo.currentPlan(), isNull);
  });

  test('startPlan points at the first ayah and persists the pace', () async {
    await repo.startPlan(151);

    final plan = await repo.currentPlan();
    expect(plan, isNotNull);
    expect(plan!.ayahId, 1);
    expect(plan.targetPages, 151);
    expect(plan.updatedAt, isA<DateTime>());
    expect(await db.select(db.khatmaProgress).get(), hasLength(1));
  });

  test('startPlan replaces the previous plan (single active row)', () async {
    await repo.startPlan(604);
    await repo.startPlan(302);

    final plan = await repo.currentPlan();
    expect(plan!.targetPages, 302);
    expect(await db.select(db.khatmaProgress).get(), hasLength(1));
  });

  test('advanceTo moves the pointer forward and never backward', () async {
    await repo.startPlan(151);

    await repo.advanceTo(9);
    expect((await repo.currentPlan())!.ayahId, 9);

    await repo.advanceTo(3);
    expect((await repo.currentPlan())!.ayahId, 9);

    await repo.advanceTo(9);
    expect((await repo.currentPlan())!.ayahId, 9);
  });

  test('advanceTo without a plan is a no-op', () async {
    await repo.advanceTo(9);

    expect(await repo.currentPlan(), isNull);
    expect(await db.select(db.khatmaProgress).get(), isEmpty);
  });

  test('complete() jumps the pointer to the last ayah', () async {
    await repo.startPlan(604);
    await repo.complete();

    final plan = await repo.currentPlan();
    expect(plan!.ayahId, 6236);
    expect(await repo.pagesFromAyah(plan.ayahId), 604);
  });

  test('reset deletes the plan', () async {
    await repo.startPlan(604);
    await repo.reset();

    expect(await repo.currentPlan(), isNull);
  });

  test('pagesFromAyah and anchorFor resolve seeded rows', () async {
    expect(await repo.pagesFromAyah(8), 5);
    expect(await repo.anchorFor(8),
        (page: 5, surahId: 1, numberInSurah: 4));
    expect(await repo.pagesFromAyah(9999), isNull);
    expect(await repo.anchorFor(9999), isNull);
  });

  test('firstAyahIdOfPage returns the smallest id on that page', () async {
    expect(await repo.firstAyahIdOfPage(1), 1);
    expect(await repo.firstAyahIdOfPage(2), 3);
    expect(await repo.firstAyahIdOfPage(604), 91);
    expect(await repo.firstAyahIdOfPage(7), isNull);
  });
}
