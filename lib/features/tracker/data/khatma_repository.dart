import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

/// One active wird/khatma plan row (single-row by invariant).
class KhatmaPlan {
  const KhatmaPlan({
    required this.ayahId,
    required this.targetPages,
    required this.updatedAt,
  });

  /// Read-up-to pointer: the global ayah id (1..6236) the plan has reached.
  final int ayahId;

  final int targetPages;
  final DateTime updatedAt;
}

/// Persistence for the single khatma plan over [KhatmaProgress].
class KhatmaRepository {
  KhatmaRepository(this._db);

  final AppDatabase _db;

  Future<KhatmaPlan?> currentPlan() async {
    final row = await _row();
    if (row == null) return null;
    return KhatmaPlan(
      ayahId: row.ayahId,
      targetPages: row.targetPages,
      updatedAt: row.updatedAt,
    );
  }

  /// Starts a fresh plan, replacing any existing row (one active plan).
  Future<void> startPlan(int targetPages) async {
    final first = await _firstAyahId() ?? 1;
    await _db.transaction(() async {
      await _db.delete(_db.khatmaProgress).go();
      await _db.into(_db.khatmaProgress).insert(
            KhatmaProgressCompanion.insert(
              ayahId: first,
              targetPages: targetPages,
            ),
          );
    });
  }

  /// Advances the read-up-to pointer to [ayahId]; max-wins (never backward)
  /// and a no-op while no plan is active.
  Future<void> advanceTo(int ayahId) async {
    final row = await _row();
    if (row == null || ayahId <= row.ayahId) return;
    await (_db.update(_db.khatmaProgress)..where((t) => t.id.equals(row.id)))
        .write(KhatmaProgressCompanion(
      ayahId: Value(ayahId),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Jumps the pointer to the last ayah of the mushaf (khatma completion).
  Future<void> complete() async {
    final last = await _lastAyahId();
    if (last == null) return;
    await advanceTo(last);
  }

  /// Deletes the plan row (the card falls back to its setup state).
  Future<void> reset() async {
    await _db.delete(_db.khatmaProgress).go();
  }

  Future<int?> pagesFromAyah(int ayahId) async =>
      (await anchorFor(ayahId))?.page;

  /// Mushaf coordinates of [ayahId]; null when the id is unknown.
  Future<({int page, int surahId, int numberInSurah})?> anchorFor(
      int ayahId) async {
    final row =
        await (_db.select(_db.ayahs)..where((a) => a.id.equals(ayahId)))
            .getSingleOrNull();
    if (row == null) return null;
    return (
      page: row.page,
      surahId: row.surahId,
      numberInSurah: row.numberInSurah,
    );
  }

  /// First ayah id on mushaf [page]; null when the page is unknown.
  Future<int?> firstAyahIdOfPage(int page) async {
    final row = await (_db.select(_db.ayahs)
          ..where((a) => a.page.equals(page))
          ..orderBy([(a) => OrderingTerm.asc(a.id)])
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }

  Future<KhatmaProgressData?> _row() =>
      _db.select(_db.khatmaProgress).getSingleOrNull();

  Future<int?> _firstAyahId() async {
    final row = await (_db.select(_db.ayahs)
          ..orderBy([(a) => OrderingTerm.asc(a.id)])
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }

  Future<int?> _lastAyahId() async {
    final row = await (_db.select(_db.ayahs)
          ..orderBy([(a) => OrderingTerm.desc(a.id)])
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }
}
