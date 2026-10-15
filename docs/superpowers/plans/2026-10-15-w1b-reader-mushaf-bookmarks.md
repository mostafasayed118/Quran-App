# Quran Yahdi — Wave 1b (Reader + Mushaf + Bookmarks + Last-Read) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Ship the reading core: ayah reader (verse mode + mushaf page mode), per-ayah bookmarks (+ list screen), and reading-position persistence — all from the W1a bundled database.

**Architecture:** W1a pattern extended: `AyahRepository` + `LastReadRepository` (drift, pure Dart) → `ReaderCubit`/`BookmarksCubit` (flutter_bloc, Freezed sealed states) → screens (Material 3, D6 tokens). Mushaf mode = `PageView` over the surah's own content pages (ayahs grouped by `page` metadata; surah-scoped in v1 — a page shared with a neighboring surah renders only this surah's ayahs on it).

**Tech Stack:** W0/W1a stack only. ONE new package: `scrollable_positioned_list` (jump-to-ayah) — **resolvability pre-proven**: this repo's pre-W0 `pubspec.lock` resolved it at 0.3.8 on this same SDK. No test-helper deps (W1a Errata v4 lesson).

**Spec:** `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md`. Prior waves: W1a plan conventions. PM campaign ledger pins the wave lessons.

## Global Constraints

- All W0/W1a rules binding: add the ONE new package via `flutter pub add scrollable_positioned_list`; analyze ends 0 issues; TDD red→green where stated; explicit-pathspec commits with the exact messages below; NO push; checkbox ticks committed at close-out; one active writer on `main`.
- **PM probe (basmond policy, verified 2026-10-15 against the committed sqlite):** ayah texts do NOT embed the basmala (Baqarah 1:1 = "الم"). Policy: render a basmala banner above the reading body for every surah EXCEPT 1 (Fatiha — its verse 1 IS the basmala) and 9 (At-Tawbah — by design).
- **Wave lessons (binding, from the PM ledger):** drift companion PK columns wrap `Value(...)` (incl. `SettingsTableCompanion.insert(key: Value(...))`); class-specific drift imports (`package:drift/native.dart` for `NativeDatabase`); NO flutter import inside `data/`/cubits/states; seeding uses `db.batch((b) => b.insertAll(...))` (no `insertAll` on statements); widget tests must NOT hold a live drift watch — use the teardown-safe `Stream.value` repository override exactly as provided below; plain `test()` only; gen-l10n renders western digits for int placeholders — the page indicator therefore takes a pre-formatted String (Arabic-Indic via the Task 2 helper).

---

### Task 1: Start gate

- [x] **Step 1: Record verbatim**

```powershell
git rev-parse --short=7 HEAD; git status --porcelain; flutter --version
```
Expected: HEAD `c2ae2fc` or later; intervening commits touch ONLY `docs/` (verify with `git log --oneline -4`); porcelain empty; branch `main`. Anything else → STOP.

---

### Task 2: Arabic-Indic numerals helper (pure)

**Files:**
- Create: `lib/core/utils/arabic_numbers.dart`
- Test: `test/arabic_numbers_test.dart`

**Interfaces:**
- Produces: `extension ArabicIndicInt on int { String get toArabicIndic; }` — converts the decimal representation of the int to Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩); non-digit characters pass through unchanged (there are none in an int, but the implementation iterates chars so `"12"`-style reuse stays possible).

- [x] **Step 1: Failing test — `test/arabic_numbers_test.dart` (verbatim)**

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/arabic_numbers.dart';

void main() {
  test('converts western digits to Arabic-Indic', () {
    expect(0.toArabicIndic, '٠');
    expect(7.toArabicIndic, '٧');
    expect(12.toArabicIndic, '١٢');
    expect(6236.toArabicIndic, '٦٢٣٦');
  });
}
```

- [x] **Step 2: Run → FAIL. Implement `lib/core/utils/arabic_numbers.dart` (verbatim)**

```dart
const List<String> _arabicIndicDigits = [
  '٠',
  '١',
  '٢',
  '٣',
  '٤',
  '٥',
  '٦',
  '٧',
  '٨',
  '٩',
];

extension ArabicIndicInt on int {
  /// Renders this int with Arabic-Indic digits (٠-٩).
  String get toArabicIndic {
    final buffer = StringBuffer();
    for (final char in toString().split('')) {
      final digit = int.tryParse(char);
      buffer.write(digit == null ? char : _arabicIndicDigits[digit]);
    }
    return buffer.toString();
  }
}
```

- [x] **Step 3: Gates + commit**

```powershell
flutter test test/arabic_numbers_test.dart
flutter analyze
git add lib/core/utils/arabic_numbers.dart test/arabic_numbers_test.dart
git commit -m "feat(w1b): arabic-indic numeral helper"
```

---

### Task 3: AyahRepository + LastReadRepository (+ DI)

**Files:**
- Create: `lib/features/quran/data/ayah_repository.dart`, `lib/features/quran/data/last_read_repository.dart`
- Modify: `lib/core/di/injector.dart`
- Test: `test/ayah_repository_test.dart`, `test/last_read_repository_test.dart`

**Interfaces:**
- Produces (`AyahRepository(AppDatabase db)`):
  - `Future<List<Ayah>> surahAyahs(int surahId)` — ordered by `numberInSurah` ascending.
  - `Future<Surah?> surahById(int surahId)`.
  - `Future<void> toggleBookmark(int ayahId)` — inserts a bookmark row when absent, deletes it when present.
  - `Stream<Set<int>> watchBookmarkedIds()` — live set of bookmarked global ayah ids.
  - `Stream<List<BookmarkEntry>> watchBookmarkEntries()` — bookmarks joined with ayah rows, newest (highest bookmark id) first; `BookmarkEntry({required Ayah ayah})`.
- Produces (`LastReadRepository(AppDatabase db)`): `Future<void> saveAyahId(int ayahId)` (upsert into the settings table under key `last_read_ayah_id`), `Future<int?> loadAyahId()`.
- DI: both registered as lazy singletons on the existing `AppDatabase`.

- [x] **Step 1: Failing tests (verbatim)**

`test/ayah_repository_test.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';

void main() {
  late AppDatabase db;
  late AyahRepository repo;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    final ayahs = [
      AyahsCompanion.insert(
          id: const Value(8), surahId: 2, numberInSurah: 1, juz: 1, page: 2,
          textUthmani: 'الم', textImlaei: 'الم'),
      AyahsCompanion.insert(
          id: const Value(9), surahId: 2, numberInSurah: 2, juz: 1, page: 2,
          textUthmani: 'ذلك الكتاب', textImlaei: 'ذلك الكتاب'),
      AyahsCompanion.insert(
          id: const Value(10), surahId: 2, numberInSurah: 3, juz: 1, page: 3,
          textUthmani: 'الذين يؤمنون', textImlaei: 'الذين يؤمنون'),
    ];
    await db.batch((b) => b.insertAll(db.ayahs, ayahs));
    repo = AyahRepository(db);
  });

  tearDown(() async => db.close());

  test('surahAyahs returns the surah ordered by numberInSurah', () async {
    final list = await repo.surahAyahs(2);
    expect(list.map((a) => a.numberInSurah).toList(), [1, 2, 3]);
    expect(list.first.textImlaei, 'الم');
  });

  test('toggleBookmark inserts then removes', () async {
    await repo.toggleBookmark(9);
    expect((await repo.watchBookmarkedIds().first), contains(9));

    await repo.toggleBookmark(9);
    expect((await repo.watchBookmarkedIds().first), isNot(contains(9)));
  });

  test('watchBookmarkEntries joins ayah rows', () async {
    await repo.toggleBookmark(10);
    final entries = await repo.watchBookmarkEntries().first;
    expect(entries, hasLength(1));
    expect(entries.single.ayah.surahId, 2);
    expect(entries.single.ayah.numberInSurah, 3);
  });
}
```

`test/last_read_repository_test.dart`:
```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';

void main() {
  late AppDatabase db;
  late LastReadRepository repo;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = LastReadRepository(db);
  });

  tearDown(() async => db.close());

  test('save overwrites; load returns null when unset', () async {
    expect(await repo.loadAyahId(), isNull);
    await repo.saveAyahId(8);
    expect(await repo.loadAyahId(), 8);
    await repo.saveAyahId(102);
    expect(await repo.loadAyahId(), 102);
  });
}
```

- [x] **Step 2: Run both → FAIL. Implement the two repositories (verbatim).**

`lib/features/quran/data/ayah_repository.dart`:
```dart
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

/// One readable bookmark row: the bookmark joined with its ayah.
class BookmarkEntry {
  const BookmarkEntry({required this.ayah});

  final Ayah ayah;
}

class AyahRepository {
  AyahRepository(this._db);

  final AppDatabase _db;

  Future<List<Ayah>> surahAyahs(int surahId) {
    final query = _db.select(_db.ayahs)
      ..where((a) => a.surahId.equals(surahId))
      ..orderBy([(a) => OrderingTerm.asc(a.numberInSurah)]);
    return query.get();
  }

  Future<Surah?> surahById(int surahId) =>
      (_db.select(_db.surahs)..where((s) => s.id.equals(surahId)))
          .getSingleOrNull();

  Future<void> toggleBookmark(int ayahId) async {
    final existing = await (_db.select(_db.bookmarks)
          ..where((b) => b.ayahId.equals(ayahId)))
        .get();
    if (existing.isEmpty) {
      await _db.into(_db.bookmarks)
          .insert(BookmarksCompanion.insert(ayahId: ayahId));
    } else {
      await (_db.delete(_db.bookmarks)
            ..where((b) => b.ayahId.equals(ayahId)))
          .go();
    }
  }

  Stream<Set<int>> watchBookmarkedIds() {
    return _db.select(_db.bookmarks).watch().map(
          (rows) => rows.map((b) => b.ayahId).toSet(),
        );
  }

  Stream<List<BookmarkEntry>> watchBookmarkEntries() {
    final query = _db.select(_db.bookmarks).join([
      innerJoin(_db.ayahs, _db.ayahs.id.equalsExp(_db.bookmarks.ayahId)),
    ])
      ..orderBy([OrderingTerm.desc(_db.bookmarks.id)]);
    return query.watch().map(
          (rows) => rows
              .map((row) => BookmarkEntry(ayah: row.readTable(_db.ayahs)))
              .toList(),
        );
  }
}
```

`lib/features/quran/data/last_read_repository.dart`:
```dart
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

const lastReadAyahIdKey = 'last_read_ayah_id';

class LastReadRepository {
  LastReadRepository(this._db);

  final AppDatabase _db;

  Future<void> saveAyahId(int ayahId) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: Value(lastReadAyahIdKey),
            value: ayahId.toString(),
          ),
        );
  }

  Future<int?> loadAyahId() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(lastReadAyahIdKey)))
        .getSingleOrNull();
    if (row == null) return null;
    return int.tryParse(row.value);
  }
}
```
(`SettingsTable`'s PK is `key`, so `key:` takes `Value(...)` — W1a lesson, applied.)

- [x] **Step 3: DI — append inside `configureDependencies` (after the existing three registrations), + imports**

```dart
  getIt.registerLazySingleton<AyahRepository>(() => AyahRepository(db));
  getIt.registerLazySingleton<LastReadRepository>(() => LastReadRepository(db));
```
```dart
import '../../features/quran/data/ayah_repository.dart';
import '../../features/quran/data/last_read_repository.dart';
```

- [x] **Step 4: Gates + commit**

```powershell
flutter test test/ayah_repository_test.dart test/last_read_repository_test.dart
flutter analyze
git add lib/features/quran/data lib/core/di/injector.dart test/ayah_repository_test.dart test/last_read_repository_test.dart
git commit -m "feat(w1b): ayah + last-read repositories (bookmarks, joins, DI)"
```

---

### Task 4: Reader state + cubit (+ mushaf grouping)

**Files:**
- Create: `lib/features/quran/presentation/reader/mushaf_page_block.dart`, `lib/features/quran/presentation/reader/reader_state.dart`, `lib/features/quran/presentation/reader/reader_cubit.dart`, generated `reader_state.freezed.dart`
- Test: `test/mushaf_grouping_test.dart`, `test/reader_cubit_test.dart`

**Interfaces:**
- Produces (`mushaf_page_block.dart`): `class MushafPageBlock { final int page; final List<Ayah> ayahs; }` + `List<MushafPageBlock> groupAyahsByPage(List<Ayah> ayahs)` — one block per distinct page (sorted ascending); ayahs inside sorted by `numberInSurah`; pages where the surah has no ayahs are omitted (surah-scoped mushaf, v1).
- Produces (`reader_state.dart`): `enum ReaderMode { verses, mushaf }` and Freezed sealed:
  - `ReaderState.loading({required int surahId, required int initialAyah})`
  - `ReaderState.ready({required int surahId, required String surahName, required int initialAyah, required List<Ayah> ayahs, required List<MushafPageBlock> mushafPages, ReaderMode mode = verses, Set<int> bookmarkedAyahIds = {}, bool showBasmala = true})`
  - `ReaderState.error({required String message})`
- Produces (`reader_cubit.dart`): `ReaderCubit({required AyahRepository ayahRepository, required LastReadRepository lastReadRepository, required int surahId, required int initialAyah})`; methods `void toggleMode()`, `Future<void> toggleBookmark(int ayahId)` (DB toggle; state updates arrive via the bookmarks watch), `Future<void> onMushafPageChanged(int blockIndex)` (persists the block's first ayah id as last-read). On load: emits ready, persists the start-ayah id as last-read, and derives `showBasmala = surahId != 1 && surahId != 9` (PM probe policy).

- [x] **Step 1: Failing tests (verbatim)**

`test/mushaf_grouping_test.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/mushaf_page_block.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    final ayahs = [
      AyahsCompanion.insert(
          id: const Value(8), surahId: 2, numberInSurah: 1, juz: 1, page: 2,
          textUthmani: 'الم', textImlaei: 'الم'),
      AyahsCompanion.insert(
          id: const Value(9), surahId: 2, numberInSurah: 2, juz: 1, page: 2,
          textUthmani: 'ذلك الكتاب', textImlaei: 'ذلك الكتاب'),
      AyahsCompanion.insert(
          id: const Value(10), surahId: 2, numberInSurah: 3, juz: 1, page: 3,
          textUthmani: 'الذين يؤمنون', textImlaei: 'الذين يؤمنون'),
      AyahsCompanion.insert(
          id: const Value(11), surahId: 2, numberInSurah: 4, juz: 1, page: 4,
          textUthmani: 'وبما رزقناهم', textImlaei: 'وبما رزقناهم'),
      AyahsCompanion.insert(
          id: const Value(12), surahId: 2, numberInSurah: 5, juz: 1, page: 4,
          textUthmani: 'وبالآخرة هم يقينون', textImlaei: 'وبالآخرة هم يقينون'),
      AyahsCompanion.insert(
          id: const Value(13), surahId: 2, numberInSurah: 6, juz: 1, page: 4,
          textUthmani: 'أولئك على هدى', textImlaei: 'أولئك على هدى'),
    ];
    await db.batch((b) => b.insertAll(db.ayahs, ayahs));
  });

  tearDown(() async => db.close());

  test('groups surah ayahs into sorted page blocks', () async {
    final repo = AyahRepository(db);
    final blocks = groupAyahsByPage(await repo.surahAyahs(2));

    expect(blocks.map((b) => b.page).toList(), [2, 3, 4]);
    expect(blocks.map((b) => b.ayahs.length).toList(), [2, 1, 3]);
    expect(blocks.first.ayahs.first.numberInSurah, 1);
  });
}
```

`test/reader_cubit_test.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/mushaf_page_block.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';

void main() {
  late AppDatabase db;
  late AyahRepository ayahs;
  late LastReadRepository lastRead;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    final fatiha = [
      AyahsCompanion.insert(
          id: const Value(1), surahId: 1, numberInSurah: 1, juz: 1, page: 1,
          textUthmani: 'بسم الله الرحمن الرحيم', textImlaei: 'بسم الله الرحمن الرحيم'),
      AyahsCompanion.insert(
          id: const Value(2), surahId: 1, numberInSurah: 2, juz: 1, page: 1,
          textUthmani: 'الحمد لله رب العالمين', textImlaei: 'الحمد لله رب العالمين'),
      AyahsCompanion.insert(
          id: const Value(3), surahId: 1, numberInSurah: 3, juz: 1, page: 1,
          textUthmani: 'الرحمن الرحيم', textImlaei: 'الرحمن الرحيم'),
    ];
    final baqarah = [
      AyahsCompanion.insert(
          id: const Value(8), surahId: 2, numberInSurah: 1, juz: 1, page: 2,
          textUthmani: 'الم', textImlaei: 'الم'),
      AyahsCompanion.insert(
          id: const Value(9), surahId: 2, numberInSurah: 2, juz: 1, page: 2,
          textUthmani: 'ذلك الكتاب', textImlaei: 'ذلك الكتاب'),
    ];
    await db.batch((b) => b.insertAll(db.ayahs, fatiha));
    await db.batch((b) => b.insertAll(db.ayahs, baqarah));
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
              id: const Value(1), nameAr: 'الفاتحة', nameEn: 'Al-Fatihah',
              revelationType: 'makkah', ayahCount: 3, pagesStart: 1, pagesEnd: 1),
        );
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
              id: const Value(2), nameAr: 'البقرة', nameEn: 'Al-Baqarah',
              revelationType: 'madinah', ayahCount: 2, pagesStart: 2, pagesEnd: 2),
        );
    ayahs = AyahRepository(db);
    lastRead = LastReadRepository(db);
  });

  tearDown(() async => db.close());

  test('loads ready state; basmala banner policy per surah', () async {
    ReaderCubit? cubit = ReaderCubit(
        ayahRepository: ayahs, lastReadRepository: lastRead,
        surahId: 2, initialAyah: 0);
    final ready = await cubit.stream
        .firstWhere((s) => s is ReaderReady) as ReaderReady;
    expect(ready.showBasmala, isTrue);
    expect(ready.surahName, 'البقرة');
    expect(ready.mushafPages, isNotEmpty);
    await cubit.close();

    cubit = ReaderCubit(
        ayahRepository: ayahs, lastReadRepository: lastRead,
        surahId: 1, initialAyah: 0);
    final fatihaReady =
        await cubit.stream.firstWhere((s) => s is ReaderReady) as ReaderReady;
    expect(fatihaReady.showBasmala, isFalse);
    await cubit.close();
  });

  test('toggleBookmark flips the bookmarkedIds set (via watch)', () async {
    final cubit = ReaderCubit(
        ayahRepository: ayahs, lastReadRepository: lastRead,
        surahId: 2, initialAyah: 0);
    await cubit.stream.firstWhere((s) => s is ReaderReady);
    await cubit.toggleBookmark(8);
    await cubit.stream.firstWhere(
        (s) => s is ReaderReady && (s).bookmarkedAyahIds.contains(8));
    await cubit.toggleBookmark(8);
    await cubit.stream.firstWhere(
        (s) => s is ReaderReady && !(s).bookmarkedAyahIds.contains(8));
    await cubit.close();
  });

  test('toggleMode flips verses <-> mushaf; page change persists last-read',
      () async {
    final cubit = ReaderCubit(
        ayahRepository: ayahs, lastReadRepository: lastRead,
        surahId: 2, initialAyah: 0);
    final ready = await cubit.stream
        .firstWhere((s) => s is ReaderReady) as ReaderReady;
    expect(ready.mode, ReaderMode.verses);
    cubit.toggleMode();
    final mushaf = cubit.state as ReaderReady;
    expect(mushaf.mode, ReaderMode.mushaf);
    await cubit.onMushafPageChanged(0);
    expect(await lastRead.loadAyahId(), 8);
    await cubit.close();
  });
}
```
- [x] **Step 2: Run both → FAIL. Implement the three files (verbatim).**

`lib/features/quran/presentation/reader/mushaf_page_block.dart`:
```dart
import '../../../../core/db/app_database.dart';

/// A single rendered page block in mushaf mode: the surah's ayahs that share
/// one mushaf page. Pages the surah owns no ayahs on are omitted (surah-
/// scoped mushaf, v1).
class MushafPageBlock {
  const MushafPageBlock({required this.page, required this.ayahs});

  final int page;
  final List<Ayah> ayahs;
}

List<MushafPageBlock> groupAyahsByPage(List<Ayah> ayahs) {
  final byPage = <int, List<Ayah>>{};
  for (final ayah in ayahs) {
    byPage.putIfAbsent(ayah.page, () => <Ayah>[]).add(ayah);
  }
  final pages = byPage.keys.toList()..sort();
  return [
    for (final page in pages)
      MushafPageBlock(
        page: page,
        ayahs: byPage[page]!
          ..sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah)),
      ),
  ];
}
```

`lib/features/quran/presentation/reader/reader_state.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/db/app_database.dart';
import 'mushaf_page_block.dart';

part 'reader_state.freezed.dart';

enum ReaderMode { verses, mushaf }

@freezed
sealed class ReaderState with _$ReaderState {
  const factory ReaderState.loading({
    required int surahId,
    required int initialAyah,
  }) = ReaderLoading;

  const factory ReaderState.ready({
    required int surahId,
    required String surahName,
    required int initialAyah,
    required List<Ayah> ayahs,
    required List<MushafPageBlock> mushafPages,
    @Default(ReaderMode.verses) ReaderMode mode,
    @Default(<int>{}) Set<int> bookmarkedAyahIds,
    @Default(true) bool showBasmala,
  }) = ReaderReady;

  const factory ReaderState.error({required String message}) = ReaderError;
}
```

`lib/features/quran/presentation/reader/reader_cubit.dart`:
```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../data/ayah_repository.dart';
import '../../data/last_read_repository.dart';
import 'mushaf_page_block.dart';
import 'reader_state.dart';

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit({
    required AyahRepository ayahRepository,
    required LastReadRepository lastReadRepository,
    required int surahId,
    required int initialAyah,
  })  : _ayahRepository = ayahRepository,
        _lastReadRepository = lastReadRepository,
        _surahId = surahId,
        _initialAyah = initialAyah,
        super(ReaderState.loading(surahId: surahId, initialAyah: initialAyah)) {
    _bookmarksSub = ayahRepository.watchBookmarkedIds().listen(_onBookmarks);
    _load();
  }

  final AyahRepository _ayahRepository;
  final LastReadRepository _lastReadRepository;
  final int _surahId;
  final int _initialAyah;
  StreamSubscription<Set<int>>? _bookmarksSub;
  final Set<int> _bookmarkedIds = <int>{};

  Future<void> _load() async {
    try {
      final results =
          await Future.wait([_ayahRepository.surahById(_surahId), _ayahRepository.surahAyahs(_surahId)]);
      final surah = results[0] as Surah?;
      final ayahs = results[1] as List<Ayah>;
      final startList = ayahs
          .where((a) => a.numberInSurah == _initialAyah)
          .toList();
      _lastReadRepository
          .saveAyahId(startList.isNotEmpty ? startList.first.id : (ayahs.isNotEmpty ? ayahs.first.id : 0));
      if (isClosed) return;
      emit(ReaderState.ready(
        surahId: _surahId,
        surahName: surah?.nameAr ?? '',
        initialAyah: _initialAyah,
        ayahs: ayahs,
        mushafPages: groupAyahsByPage(ayahs),
        bookmarkedAyahIds: Set<int>.of(_bookmarkedIds),
        showBasmala: _surahId != 1 && _surahId != 9,
      ));
    } on Object catch (error) {
      if (isClosed) return;
      emit(ReaderState.error(message: error.toString()));
    }
  }

  void _onBookmarks(Set<int> ids) {
    _bookmarkedIds
      ..clear()
      ..addAll(ids);
    final current = state;
    if (current is ReaderReady && !isClosed) {
      emit(current.copyWith(bookmarkedAyahIds: Set<int>.of(_bookmarkedIds)));
    }
  }

  void toggleMode() {
    final current = state;
    if (current is! ReaderReady || isClosed) return;
    emit(current.copyWith(
      mode: current.mode == ReaderMode.verses
          ? ReaderMode.mushaf
          : ReaderMode.verses,
    ));
  }

  Future<void> toggleBookmark(int ayahId) async {
    await _ayahRepository.toggleBookmark(ayahId);
  }

  Future<void> onMushafPageChanged(int blockIndex) async {
    final current = state;
    if (current is! ReaderReady) return;
    if (blockIndex < 0 || blockIndex >= current.mushafPages.length) return;
    final pageAyahs = current.mushafPages[blockIndex].ayahs;
    if (pageAyahs.isEmpty) return;
    await _lastReadRepository.saveAyahId(pageAyahs.first.id);
  }

  @override
  Future<void> close() {
    _bookmarksSub?.cancel();
    return super.close();
  }
}
```

- [x] **Step 3: Generate + gates + commit**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test test/mushaf_grouping_test.dart test/reader_cubit_test.dart
flutter analyze
git add lib/features/quran/presentation/reader test/mushaf_grouping_test.dart test/reader_cubit_test.dart
git commit -m "feat(w1b): reader cubit (freezed state, mushaf grouping, bookmark watch)"
```
Expected: both test files pass (the ready transition races are settled via `stream.firstWhere` in the tests); analyze 0 issues.

---

### Task 5: Reader screen + mushaf pager (UI)

**Files:**
- Modify (dependency): `pubspec.yaml`/`pubspec.lock` — `flutter pub add scrollable_positioned_list` (pre-proven resolvable in this repo's pre-W0 lock at 0.3.8)
- Create: `lib/features/quran/presentation/reader/reader_screen.dart`
- Modify: `lib/app/router.dart` (`/quran/reader` route), `lib/features/quran/presentation/index/surah_index_screen.dart` (wire the W1a-inert row tap), `lib/l10n/app_ar.arb` + `lib/l10n/app_en.arb` (additive), regenerate l10n
- Test: `test/reader_screen_test.dart`

**Interfaces:**
- Consumes: `ReaderCubit` (Task 4), `ArabicIndicInt` (Task 2), `AppLocalizations`.
- Produces: route `/quran/reader?surah=N&ayah=M` (ints parsed in the router; `ayah` 0 = top). Index rows push it via `context.push`.

- [x] **Step 1: l10n keys (additive only, both files)**

AR appended:
```json
  "mushafMode": "وضع المصحف",
  "versesMode": "وضع الآيات",
  "bookmarks": "العلامات المرجعية",
  "bookmarkSave": "احفظ الآية",
  "bookmarkRemove": "أزل الحفظ",
  "noBookmarks": "لا توجد علامات مرجعية بعد",
  "pageIndicator": "صفحة {page}",
  "@pageIndicator": { "placeholders": { "page": { "type": "String" } } }
```
EN appended:
```json
  "mushafMode": "Mushaf Mode",
  "versesMode": "Verses Mode",
  "bookmarks": "Bookmarks",
  "bookmarkSave": "Bookmark this ayah",
  "bookmarkRemove": "Remove bookmark",
  "noBookmarks": "No bookmarks yet",
  "pageIndicator": "Page {page}",
  "@pageIndicator": { "placeholders": { "page": { "type": "String" } } }
```

- [x] **Step 2: Dep + regenerate**

```powershell
flutter pub add scrollable_positioned_list
flutter pub get
flutter gen-l10n
```
(Solver failure → STOP with evidence; no substitute improv.)

- [x] **Step 3: Router — add inside the routes list (verbatim), + imports**

```dart
      GoRoute(
        path: '/quran/reader',
        builder: (context, state) {
          final surah =
              int.tryParse(state.uri.queryParameters['surah'] ?? '') ?? 1;
          final ayah =
              int.tryParse(state.uri.queryParameters['ayah'] ?? '') ?? 0;
          return BlocProvider<ReaderCubit>(
            create: (_) => ReaderCubit(
              ayahRepository: getIt<AyahRepository>(),
              lastReadRepository: getIt<LastReadRepository>(),
              surahId: surah,
              initialAyah: ayah,
            ),
            child: const ReaderScreen(),
          );
        },
      ),
```
```dart
import '../features/quran/data/last_read_repository.dart';
import '../features/quran/presentation/reader/reader_cubit.dart';
import '../features/quran/presentation/reader/reader_screen.dart';
```
(`flutter_bloc`, `getIt`, `AyahRepository` imports already exist from W1a.)

- [x] **Step 4: Wire the W1a index row tap — in `surah_index_screen.dart`:**
  Add import `import 'package:go_router/go_router.dart';` and replace the `// W1b:` inert comment inside `_SurahRow` `onTap` with:
```dart
        onTap: () => context
            .push('/quran/reader?surah=${surah.id}&ayah=0'),
```

- [x] **Step 5: Widget test FIRST — `test/reader_screen_test.dart` (verbatim; teardown-safe override baked in per the ledger lesson)**

```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_screen.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db);
  @override
  Stream<Set<int>> watchBookmarkedIds() =>
      Stream<Set<int>>.value(const <int>{});
}

void main() {
  late AppDatabase db;
  late AyahRepository repo;
  late LastReadRepository lastRead;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    final baqarah = [
      AyahsCompanion.insert(
          id: const Value(8), surahId: 2, numberInSurah: 1, juz: 1, page: 2,
          textUthmani: 'الم', textImlaei: 'الم'),
      AyahsCompanion.insert(
          id: const Value(9), surahId: 2, numberInSurah: 2, juz: 1, page: 2,
          textUthmani: 'ذلك الكتاب', textImlaei: 'ذلك الكتاب'),
      AyahsCompanion.insert(
          id: const Value(10), surahId: 2, numberInSurah: 3, juz: 1, page: 3,
          textUthmani: 'الذين يؤمنون', textImlaei: 'الذين يؤمنون'),
    ];
    final fatiha = [
      AyahsCompanion.insert(
          id: const Value(1), surahId: 1, numberInSurah: 1, juz: 1, page: 1,
          textUthmani: 'بسم الله الرحمن الرحيم', textImlaei: 'بسم الله الرحمن الرحيم'),
    ];
    await db.batch((b) => b.insertAll(db.ayahs, baqarah));
    await db.batch((b) => b.insertAll(db.ayahs, fatiha));
    lastRead = LastReadRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Widget> host(int surahId) async {
    repo = _TeardownSafeAyahRepository(db);
    final cubit = ReaderCubit(
        ayahRepository: repo, lastReadRepository: lastRead,
        surahId: surahId, initialAyah: 0);
    // Wait for the async load so the first frame is ready.
    while (cubit.state is! ReaderReady) {
      await Future<void>.delayed(Duration.zero);
    }
    return BlocProvider<ReaderCubit>.value(
      value: cubit,
      child: const ReaderScreen(),
    );
  }

  testWidgets('surah 2 shows basmala banner and ayah cards in verse mode',
      (tester) async {
    final screen = await host(2);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: screen,
    ));
    await tester.pumpAndSettle();

    expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
    expect(find.text('الم'), findsOneWidget);
    expect(find.text('بسم الله الرحمن الرحيم'), findsNothing,
        reason: 'Fatiha text is not part of surah 2');
  });

  testWidgets('bookmark heart toggles the DB row', (tester) async {
    final screen = await host(2);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: screen,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bookmark_border).first);
    await tester.pumpAndSettle();

    final rows = await db.select(db.bookmarks).get();
    expect(rows, hasLength(1));
    expect(rows.single.ayahId, 8);
  });

  testWidgets('mushaf mode renders page blocks with the page indicator',
      (tester) async {
    final screen = await host(2);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: screen,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('وضع المصحف'));
    await tester.pumpAndSettle();

    expect(find.textContaining('صفحة'), findsOneWidget);
  });
}
```
(The two tests above share the same delegate setup via the local helper lambdas; no further wiring is needed.)

- [x] **Step 6: Implement `lib/features/quran/presentation/reader/reader_screen.dart` (verbatim, complete)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import 'reader_cubit.dart';
import 'reader_state.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      builder: (context, state) => switch (state) {
        ReaderLoading() =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        ReaderError(:final message) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(message)),
          ),
        ReaderReady() => _ReadyView(state: state),
      },
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.state});

  final ReaderReady state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<ReaderCubit>();
    final isVerses = state.mode == ReaderMode.verses;
    return Scaffold(
      appBar: AppBar(
        title: Text(state.surahName),
        actions: [
          IconButton(
            tooltip: isVerses ? loc.mushafMode : loc.versesMode,
            icon: Icon(isVerses ? Icons.menu_book : Icons.auto_stories),
            onPressed: cubit.toggleMode,
          ),
          IconButton(
            tooltip: loc.bookmarks,
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => context.push('/bookmarks'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.showBasmala)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontFamily: QuranFonts.meQuran,
                  fontSize: 22,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          Expanded(
            child: isVerses ? _VersesList(state: state) : _MushafPager(state: state),
          ),
        ],
      ),
    );
  }
}

class _VersesList extends StatelessWidget {
  const _VersesList({required this.state});

  final ReaderReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();
    final initialIndex =
        state.ayahs.indexWhere((a) => a.numberInSurah == state.initialAyah);
    final controller = ItemScrollController();
    return ScrollablePositionedList.builder(
      initialScrollIndex: initialIndex > 0 ? initialIndex : 0,
      itemScrollController: controller,
      itemCount: state.ayahs.length,
      itemBuilder: (context, index) {
        final ayah = state.ayahs[index];
        return _AyahCard(
          ayah: ayah,
          bookmarked: state.bookmarkedAyahIds.contains(ayah.id),
          onToggle: () => cubit.toggleBookmark(ayah.id),
        );
      },
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.ayah,
    required this.bookmarked,
    required this.onToggle,
  });

  final Ayah ayah;
  final bool bookmarked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bookmarked ? colors.secondary : Theme.of(context).dividerColor,
          width: bookmarked ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            ayah.textUthmani,
            style: TextStyle(
              fontFamily: QuranFonts.quran,
              fontSize: 24,
              height: 2,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                '﴿${ayah.numberInSurah.toArabicIndic}﴾',
                style: TextStyle(
                  fontFamily: QuranFonts.meQuran,
                  fontSize: 16,
                  color: colors.secondary,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: bookmarked ? loc.bookmarkRemove : loc.bookmarkSave,
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: bookmarked ? colors.secondary : null,
                ),
                onPressed: onToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MushafPager extends StatefulWidget {
  const _MushafPager({required this.state});

  final ReaderReady state;

  @override
  State<_MushafPager> createState() => _MushafPagerState();
}

class _MushafPagerState extends State<_MushafPager> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    final pages = widget.state.mushafPages;
    final target = widget.state.ayahs
        .where((a) => a.numberInSurah == widget.state.initialAyah)
        .toList();
    var index = 0;
    if (target.isNotEmpty) {
      final idx = pages.indexWhere((b) => b.page == target.first.page);
      if (idx > 0) index = idx;
    }
    _controller = PageController(initialPage: index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();
    final loc = AppLocalizations.of(context);
    final pages = widget.state.mushafPages;
    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }
    return PageView.builder(
      controller: _controller,
      itemCount: pages.length,
      onPageChanged: cubit.onMushafPageChanged,
      itemBuilder: (context, i) {
        final block = pages[i];
        final text = block.ayahs
            .map((a) => '${a.textUthmani} ﴿${a.numberInSurah.toArabicIndic}﴾')
            .join(' ');
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: QuranFonts.quran,
                      fontSize: 22,
                      height: 2.2,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              Text(
                '﴿ ${loc.pageIndicator(block.page.toArabicIndic)} ﴾',
                style: TextStyle(
                  fontFamily: QuranFonts.meQuran,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [x] **Step 7: Gates + commit**

```powershell
flutter test test/reader_screen_test.dart
flutter test test
flutter analyze
git add lib/features/quran/presentation/reader lib/app/router.dart lib/features/quran/presentation/index/surah_index_screen.dart lib/l10n pubspec.yaml pubspec.lock test/reader_screen_test.dart
git commit -m "feat(w1b): reader screen (verse + mushaf pager, bookmarks, routes, l10n)"
```
(The middle `flutter test test` runs the WHOLE suite — record the exact running total in the report; expect ≥ 24 with the T2/T3/T4 additions.)

---

### Task 6: Bookmarks screen + cubit

**Files:**
- Create: `lib/features/quran/presentation/bookmarks/bookmarks_state.dart`, `lib/features/quran/presentation/bookmarks/bookmarks_cubit.dart`, `lib/features/quran/presentation/bookmarks/bookmarks_screen.dart`, generated `bookmarks_state.freezed.dart`
- Modify: `lib/app/router.dart` (`/bookmarks` route)
- Test: `test/bookmarks_screen_test.dart`

**Interfaces:**
- Consumes: `AyahRepository` (Task 3).
- Produces: `BookmarksCubit(AyahRepository repo)` — watches `watchBookmarkEntries()`, exposes `Future<void> remove(int ayahId)`; `BookmarksState.loading/ready(entries)/error`.
- Route: `/bookmarks`.

- [x] **Step 1: Failing widget test — `test/bookmarks_screen_test.dart` (verbatim; teardown-safe override again)**

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _TeardownSafeAyahRepository extends AyahRepository {
  _TeardownSafeAyahRepository(super.db, {required this.entries});
  final List<BookmarkEntry> entries;
  @override
  Stream<List<BookmarkEntry>> watchBookmarkEntries() => Stream.value(entries);
}

BookmarkEntry _entry(AppDatabase db, {required int ayahId, required String text}) {
  return BookmarkEntry(
    ayah: Ayah(
      id: ayahId,
      surahId: 2,
      numberInSurah: ayahId,
      juz: 1,
      page: 2,
      textUthmani: text,
      textImlaei: text,
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Widget host(List<BookmarkEntry> entries) =>
      BlocProvider<BookmarksCubit>(
        create: (_) => BookmarksCubit(
            _TeardownSafeAyahRepository(db, entries: entries)),
        child: const BookmarksScreen(),
      );

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: child,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('empty state message when no bookmarks', (tester) async {
    await pump(tester, host(const []));
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('lists entries with verse info and removes on delete', (tester) async {
    final text = 'ذلك الكتاب لا ريب فيه';
    final repo = _TeardownSafeAyahRepository(
      db,
      entries: [_entry(db, ayahId: 9, text: text)],
    );
    // Seed one row so the real delete has something to remove.
    await db.into(db.bookmarks)
        .insert(BookmarksCompanion.insert(ayahId: 9));
    final cubit = BookmarksCubit(repo);
    await pump(
      tester,
      BlocProvider<BookmarksCubit>.value(value: cubit, child: const BookmarksScreen()),
    );

    expect(find.textContaining(text), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(await db.select(db.bookmarks).get(), isEmpty);
  });
}

```
(The second test seeds the bookmarks table through the real DB so the delete can be verified against it; the joined entries stream arrives via the teardown-safe override.)

- [x] **Step 2: Run → FAIL. Implement the three files (verbatim).**

`lib/features/quran/presentation/bookmarks/bookmarks_state.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/ayah_repository.dart';

part 'bookmarks_state.freezed.dart';

@freezed
sealed class BookmarksState with _$BookmarksState {
  const factory BookmarksState.loading() = BookmarksLoading;

  const factory BookmarksState.ready({required List<BookmarkEntry> entries}) =
      BookmarksReady;

  const factory BookmarksState.error({required String message}) = BookmarksError;
}
```

`lib/features/quran/presentation/bookmarks/bookmarks_cubit.dart`:
```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/ayah_repository.dart';
import 'bookmarks_state.dart';

class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit(this._repo) : super(const BookmarksState.loading()) {
    _sub = _repo.watchBookmarkEntries().listen(
          (entries) {
            if (isClosed) return;
            emit(BookmarksState.ready(entries: entries));
          },
          onError: (Object error) {
            if (isClosed) return;
            emit(BookmarksState.error(message: error.toString()));
          },
        );
  }

  final AyahRepository _repo;
  StreamSubscription<List<BookmarkEntry>>? _sub;

  Future<void> remove(int ayahId) => _repo.toggleBookmark(ayahId);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
```

`lib/features/quran/presentation/bookmarks/bookmarks_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import 'bookmarks_cubit.dart';
import 'bookmarks_state.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarksCubit, BookmarksState>(
      builder: (context, state) => switch (state) {
        BookmarksLoading() =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        BookmarksError(:final message) => Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context).bookmarks)),
            body: Center(child: Text(message)),
          ),
        BookmarksReady(:final entries) => Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).bookmarks),
            ),
            body: entries.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context).noBookmarks),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final ayah = entries[index].ayah;
                      final snippet = ayah.textImlaei.length > 60
                          ? '${ayah.textImlaei.substring(0, 60)}…'
                          : ayah.textImlaei;
                      return ListTile(
                        leading: Text(
                          '${ayah.surahId.toArabicIndic}:${ayah.numberInSurah.toArabicIndic}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        title: Text(snippet),
                        subtitle: Text(
                          '${ayah.surahId.toArabicIndic} · ${ayah.numberInSurah.toArabicIndic}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              context.read<BookmarksCubit>().remove(ayah.id),
                        ),
                        onTap: () => context.push(
                            '/quran/reader?surah=${ayah.surahId}&ayah=${ayah.numberInSurah}'),
                      );
                    },
                  ),
          ),
      },
    );
  }
}
```

- [x] **Step 3: Router — add (verbatim) + import**

```dart
      GoRoute(
        path: '/bookmarks',
        builder: (_, __) => BlocProvider<BookmarksCubit>(
          create: (_) => BookmarksCubit(getIt<AyahRepository>()),
          child: const BookmarksScreen(),
        ),
      ),
```
```dart
import '../features/quran/presentation/bookmarks/bookmarks_cubit.dart';
import '../features/quran/presentation/bookmarks/bookmarks_screen.dart';
```

- [x] **Step 4: Generate + gates + commit**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test test/bookmarks_screen_test.dart
flutter analyze
git add lib/features/quran/presentation/bookmarks lib/app/router.dart test/bookmarks_screen_test.dart
git commit -m "feat(w1b): bookmarks screen + cubit (joined watch, delete, route)"
```

---

### Task 7: Close-out

- [x] **Step 1: Full gates (verbatim in report)**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter test
flutter analyze
flutter build apk --debug
git status --porcelain
flutter pub outdated
```
Expected: analyze 0; ALL tests pass — baseline 14 before this wave; expect ≈ 28 (record exact); apk exit 0 + record size; porcelain empty; all direct deps current & none discontinued.

- [x] **Step 2: Checkbox commit**

```powershell
git add docs/superpowers/plans/2026-10-15-w1b-reader-mushaf-bookmarks.md
git commit -m "docs(w1b): mark plan checkboxes complete"
```

- [x] **Step 3: FINAL REPORT — PROMPT-2 §7 format (digit-set note now EXPECTED: pageIndicator passed pre-formatted Arabic-Indic strings; confirm), APK size, unpushed count, plus the mechanical-fix disclosures section. NO PUSH. WAIT for the PM.**

---

## Self-Review (PM, pre-dispatch)

- **Spec coverage (W1b slice):** reader verse+mode toggle with jump via `initialScrollIndex` (mockup 4), mushaf PageView with page/juz footer (mockup 5 — juz merge deferred: footer shows page in v1), bookmarks toggle + list + delete (mockups 3/4), last-read persistence (spec §5) consumed now by nothing external (home/continue-chip consumers explicitly deferred to W3/W1c — recorded non-goals below), basmala policy from the PM probe (surahs 1 & 9 excluded).
- **Explicit non-goals:** tafsir/translation chips (W6, needs packs), audio play (W2), home-screen continue card (W3), juz surfer + global 604-page mushaf (W1c/later), Arabic-Indic digit theming of gen-l10n placeholders (W7 polish).
- **Placeholder scan:** none — every code block is complete and final; no debris tokens, no TBDs.
- **Type consistency:** `AyahRepository`/`LastReadRepository`/`ReaderCubit`/`ReaderState`/`BookmarksCubit`/`BookmarkEntry`/`MushafPageBlock` names used identically across tests/routers/screens; `ReaderReady` getters (`showBasmala`, `mushafPages`, `bookmarkedAyahIds`, `initialAyah`) consistent between cubit emits and widget reads; route strings identical between screen pushes and router registrations; l10n keys identical in both ARBs and in the screen usages (`mushafMode`, `versesMode`, `bookmarks`, `bookmarkSave`, `bookmarkRemove`, `noBookmarks`, `pageIndicator(String)`).
