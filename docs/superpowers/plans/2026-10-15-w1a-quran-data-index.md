# Quran Yahdi — Wave 1a (Quran Data Layer + Surah Index) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the legacy 7.4 MB Quran JSON into a pre-built bundled drift database (instant startup), and ship the Surah Index screen (list + live search + makkah/madinah metadata) replacing `/quran`'s placeholder.

**Architecture:** A dev-time CLI tool (`tools/build_quran_db.dart`) builds `assets/db/quran.sqlite` from the legacy JSON + a quran.com-fetched surah-metadata cache. The app copies this asset to app storage on first launch and opens it with the W0 `AppDatabase`. Feature-first layers: repository (drift) → cubit (flutter_bloc) → screen (Material 3, D6 tokens).

**Tech Stack:** W0 stack only — drift, flutter_bloc, get_it, go_router, gen-l10n; Freezed enters service (dep already present); dev: bloc_test.

**Spec:** `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md` (§5 schema, §6 design, D6 tokens). W0 plan conventions apply.

## PM Errata v2 — 2026-10-15 (post S6-STOP ruling; SUPERSEDES conflicting code below where edited)

An executor STOP (S6) proved four plan defects; PM verified each at source and amended the plan in place:

1. **`NativeDatabase`** is exported by `package:drift/native.dart`, NOT by `package:drift/drift.dart` → tool imports both.
2. **`min`/`max`** come from `dart:math`, NOT `package:collection` → tool imports `dart:math` (`collection` still provides `groupBy`).
3. **Drift companion `id` params are `Value<T>`** in this repo (explicit non-auto PKs; `app_database.g.dart:286,759`) → every `SurahsCompanion.insert`/`AyahsCompanion.insert` in THIS plan's code wraps `id:` in `Value(...)` (tool + all test files).
4. **`createMigrator()` is `@protected @visibleForTesting`** (drift 2.35.2) → a public seeding method was added to `AppDatabase`: `createSchemaForSeeding()` (Task 2 Step 1b) — the tool calls that; NO `// ignore:` comments anywhere.

If you are re-running after the S6 session: replace any pre-staged `tools/build_quran_db.dart` (old-plan transcription) with the amended code below before continuing.

## PM Errata v3 — 2026-10-15 (after S7-STOP ruling; SUPERSEDES conflicting code below where edited)

An S7 STOP proved a fifth defect: `dart run tools/build_quran_db.dart` executes on the pure Dart VM (no `dart:ui`), and the chain tool → `app_database.dart` → `connection.dart` → `path_provider` → flutter pulled the framework in. Ruling (executor lead 1, decouple):

- **`lib/core/db/app_database.dart` becomes pure Dart**: it NO LONGER imports `connection.dart`; the default constructor takes a REQUIRED executor; the W0 `AppDatabase()` default-open path moves to the injector (`LazyDatabase(openAppDatabase)`).
- **`lib/core/db/injector.dart`** (Task 2 Step 0b) wires `AppDatabase(LazyDatabase(openAppDatabase))` — identical runtime behavior, all W0 tests stay green (they inject executors explicitly or use the path_provider override through `configureDependencies`).
- Task 3's `connection.dart` replacement keeps its exact scope (asset bootstrap + `openAppDatabase`) — the injector already points at it, so Task 3 makes NO DI edits.
- The tool never imports `connection.dart` → pure-Dart chain (drift + meta + tables only).

## Global Constraints

- W0 rules are binding here too: dependency freshness via `flutter pub add` only; analyze ends at 0 issues; TDD where stated; explicit-pathspec commits with the exact messages below; NO push; no packages beyond this plan; checkbox ticks in THIS plan file as tasks complete (committed in Task 6).
- One active writer on the main tree; start gate decides GO/STOP.
- Base tip: `96d008b`, or later with ONLY `docs/` commits underneath (verify before continuing; anything else → STOP).

---

### Task 1: Start gate

- [ ] **Step 1: Record verbatim, in the report**

```powershell
git rev-parse --short=7 HEAD; git status --porcelain; flutter --version
```
Expected: branch `main`, clean tree. Vertex expectation: `fc31fe1` or later (PM docs commits allowed between 96d008b and tip; confirm by `git log --oneline -5`).

---

### Task 2: DB build tool

**Files:**
- Create: `tools/build_quran_db.dart`, `tools/chapters_cache.json` (tool-generated; committed after first successful run), `assets/db/quran.sqlite` (tool-generated artifact; committed)
- Modify (Errata v3, Step 0): `lib/core/db/app_database.dart` (pure-Dart refactor), `lib/core/di/injector.dart` (LazyDatabase wiring)
- Modify: `pubspec.yaml` — under `flutter: assets:` REPLACE the `- assets/json/` line with `- assets/db/` (`assets/icons/` stays; the 7.4 MB JSON remains repo-tracked as the tool input but must NOT bundle into the APK)

**Interfaces:**
- Produces: `assets/db/quran.sqlite` with all 8 W0 tables created; `surahs` = 114 rows (id 1..114; nameAr = quran.com `name_arabic`; nameEn = `name_simple`; revelationType = `revelation_place`; ayahCount = `verses_count`; pagesStart/pagesEnd = min/max of its ayah `page` values); `ayahs` = 6,236 rows (id = JSON `id`, surahId = `sura_no`, numberInSurah = `aya_no`, juz = `jozz`, page, lineStart = `line_start`, lineEnd = `line_end`, textUthmani = `aya_text`, textImlaei = `aya_text_emlaey`, sajda = false in v1). Bookmark/tracker/pack tables exist empty.
- W1b contract: ayah indexing (id / page / juz) is authoritative from this DB only.

- [ ] **Step 0 (Errata v3): decouple `app_database.dart` from Flutter + rewire the injector.**

REPLACE `lib/core/db/app_database.dart` entirely (verbatim — pure Dart, no `connection.dart` import):
```dart
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Surahs,
  Ayahs,
  Bookmarks,
  KhatmaProgress,
  PrayerLog,
  InstalledPacks,
  Downloads,
  SettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor executor) : super(executor);

  @visibleForTesting
  AppDatabase.test(super.e);

  @override
  int get schemaVersion => 1;

  /// Dev/seed helper (tools/build_quran_db.dart): creates the full schema on
  /// a fresh executor. Wraps the protected migrator; public by design.
  Future<void> createSchemaForSeeding() => createMigrator().createAll();
}
```
REPLACE the AppDatabase registration inside `lib/core/di/injector.dart` (verbatim; imports for this task — `configureDependencies` keeps every W0 line that is not the AppDatabase registration):
```dart
  getIt.registerLazySingleton<AppDatabase>(
      () => AppDatabase(LazyDatabase(openAppDatabase)));
```
```dart
import 'package:drift/drift.dart' show LazyDatabase;

import '../db/connection.dart';
```
Step-0 gates (before writing the tool):
```powershell
flutter test
flutter analyze
```
Expected: 8/8 + 0 issues. Failure here = the refactor is wrong → STOP and report.

Then DELETE the old inline `createSchemaForSeeding` note below if your transcription added it to `connection.dart` — the method lives in `app_database.dart` ONLY.

- [ ] **Step 1: Write the tool — `tools/build_quran_db.dart` (verbatim)**

```dart
// Build-time generator: assets/db/quran.sqlite from the legacy JSON + surah metadata.
// Run:  dart run tools/build_quran_db.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;

import 'package:quran_yahdi/core/db/app_database.dart';

Future<void> main() async {
  final repoRoot = Directory.current.path;
  final jsonPath = '$repoRoot\\assets\\json\\hafs_smart_v8.json';
  final dbPath = '$repoRoot\\assets\\db\\quran.sqlite';
  final cachePath = '$repoRoot\\tools\\chapters_cache.json';

  final data =
      jsonDecode(File(jsonPath).readAsStringSync()) as Map<String, dynamic>;
  final ayahList = (data['quran'] as List).cast<Map<String, dynamic>>();
  if (ayahList.length != 6236) {
    stderr.writeln('unexpected ayah count: ${ayahList.length}');
    exitCode = 1;
    return;
  }

  // Surah metadata: quran.com API v4 (id-ordered 114 chapters).
  // Fetched once, cached to tools/chapters_cache.json for deterministic reruns.
  Map<String, dynamic> chapters;
  if (File(cachePath).existsSync()) {
    chapters =
        jsonDecode(File(cachePath).readAsStringSync()) as Map<String, dynamic>;
  } else {
    final res = await http
        .get(Uri.parse('https://api.quran.com/api/v4/chapters?language=ar'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      stderr.writeln('metadata fetch failed: HTTP ${res.statusCode}');
      exitCode = 1;
      return;
    }
    final pretty = const JsonEncoder.withIndent('  ')
        .convert(jsonDecode(res.body) as Map<String, dynamic>);
    File(cachePath).writeAsStringSync(pretty);
    chapters = jsonDecode(pretty) as Map<String, dynamic>;
  }
  final chapterRows = (chapters['chapters'] as List).cast<Map<String, dynamic>>();
  if (chapterRows.length != 114) {
    stderr.writeln('unexpected chapter count: ${chapterRows.length}');
    exitCode = 1;
    return;
  }

  final dbFile = File(dbPath);
  if (dbFile.existsSync()) dbFile.deleteSync();
  final db = AppDatabase(NativeDatabase(dbFile));
  await db.createSchemaForSeeding();

  final bySurah =
      groupBy(ayahList, (Map<String, dynamic> a) => (a['sura_no'] as num).toInt());

  await db.batch((b) {
    for (final ch in chapterRows) {
      final surahNo = (ch['id'] as num).toInt();
      final ayahs = bySurah[surahNo]!;
      final pages = ayahs.map((a) => (a['page'] as num).toInt()).toList();
      b.insert(db.surahs, SurahsCompanion.insert(
        id: Value(surahNo),
        nameAr: ch['name_arabic'] as String,
        nameEn: ch['name_simple'] as String,
        revelationType: ch['revelation_place'] as String,
        ayahCount: (ch['verses_count'] as num).toInt(),
        pagesStart: pages.reduce(min),
        pagesEnd: pages.reduce(max),
      ));
    }
    for (final a in ayahList) {
      b.insert(db.ayahs, AyahsCompanion.insert(
        id: Value((a['id'] as num).toInt()),
        surahId: (a['sura_no'] as num).toInt(),
        numberInSurah: (a['aya_no'] as num).toInt(),
        juz: (a['jozz'] as num).toInt(),
        page: (a['page'] as num).toInt(),
        lineStart: a['line_start'] == null
            ? const Value.absent()
            : Value((a['line_start'] as num).toInt()),
        lineEnd: a['line_end'] == null
            ? const Value.absent()
            : Value((a['line_end'] as num).toInt()),
        textUthmani: a['aya_text'] as String,
        textImlaei: a['aya_text_emlaey'] as String,
      ));
    }
  });

  final surahCount = (await db.select(db.surahs).get()).length;
  final ayahCount = (await db.select(db.ayahs).get()).length;
  await db.close();
  stdout.writeln('surahs=$surahCount ayahs=$ayahCount bytes=${dbFile.lengthSync()}');
  if (surahCount != 114 || ayahCount != 6236) {
    stderr.writeln('COUNT MISMATCH — deleting artifact; nothing to commit');
    dbFile.deleteSync();
    exitCode = 1;
  }
}
```
(`min`/`max` come from `dart:math`; `groupBy`/`groupBy` extensions from `package:collection`; `NativeDatabase` from `package:drift/native.dart`; `Value`/companions/part-data-classes from `package:drift/drift.dart` + the generated `app_database.dart`.)

- [ ] **Step 1b (folded into Step 0 by Errata v3):** the `createSchemaForSeeding()` method now ships inside the Step-0 `app_database.dart` replacement above — nothing else to add.

- [ ] **Step 2: Deps + run (internet needed once for the metadata cache)**

```powershell
flutter pub add http collection
dart run tools/build_quran_db.dart
```
Expected: `surahs=114 ayahs=6236 bytes=<n>`, exit 0. Mismatch/HTTP failure → tool exits nonzero with its stderr line → STOP and report.

- [ ] **Step 3: pubspec assets edit (as declared under Files) + commit**

```powershell
git add tools/build_quran_db.dart tools/chapters_cache.json assets/db/quran.sqlite lib/core/db/app_database.dart lib/core/di/injector.dart pubspec.yaml pubspec.lock
git commit -m "feat(w1a): pure-dart db decouple + bundled quran sqlite (114/6236 verified)"
```

---

### Task 3: First-launch asset bootstrap

**Files:**
- Modify: `lib/core/db/connection.dart` (full replacement below)
- Test: `test/db_bootstrap_test.dart` (new)

**Interfaces:**
- Consumes: rootBundle. Produces: `copyDbAssetIfAbsent({required File target, required String assetKey, required Future<ByteData> Function(String) loadAsset})` — `@visibleForTesting` helper: copies only when `target` absent; `openAppDatabase()` uses it with `dbAssetKey = 'assets/db/quran.sqlite'` then opens via `NativeDatabase.createInBackground(file)`. Accepted debt (recorded, do not fix now): the one-time ~7 MB copy runs on the main isolate.
- DI note (Errata v3): `injector.dart` already wires `LazyDatabase(openAppDatabase)` since Task 2 Step 0b — Task 3 makes ZERO DI edits; replacing `connection.dart` transparently upgrades first-launch behavior.

- [ ] **Step 1: Failing test — `test/db_bootstrap_test.dart` (verbatim)**

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/connection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('copyDbAssetIfAbsent keeps existing file, copies when absent', () async {
    final dir = await Directory.systemTemp.createTemp('qy_bootstrap');
    final target = File('${dir.path}${Platform.pathSeparator}seed.sqlite');
    await target.writeAsBytes([1, 2, 3]);

    Future<ByteData> loader(String key) async =>
        ByteData.sublistView(Uint8List.fromList([9, 8, 7]));

    await copyDbAssetIfAbsent(
        target: target, assetKey: 'assets/db/quran.sqlite', loadAsset: loader);
    expect(await target.readAsBytes(), [1, 2, 3], reason: 'existing file untouched');

    await target.delete();
    await copyDbAssetIfAbsent(
        target: target, assetKey: 'assets/db/quran.sqlite', loadAsset: loader);
    expect(await target.readAsBytes(), [9, 8, 7], reason: 'absent file copied');

    await dir.delete(recursive: true);
  });
}
```

- [ ] **Step 2: Run → FAIL (helper missing). Then REPLACE `lib/core/db/connection.dart` entirely (verbatim):**

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const dbAssetKey = 'assets/db/quran.sqlite';

@visibleForTesting
Future<void> copyDbAssetIfAbsent({
  required File target,
  required String assetKey,
  required Future<ByteData> Function(String) loadAsset,
}) async {
  if (target.existsSync()) return;
  await target.parent.create(recursive: true);
  final data = await loadAsset(assetKey);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await target.writeAsBytes(bytes, flush: true);
}

Future<QueryExecutor> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'quran_yahdi.sqlite'));
  await copyDbAssetIfAbsent(
    target: file,
    assetKey: dbAssetKey,
    loadAsset: rootBundle.load,
  );
  return NativeDatabase.createInBackground(file);
}
```

- [ ] **Step 3: Gates + commit**

```powershell
flutter test test/db_bootstrap_test.dart
flutter analyze
git add lib/core/db/connection.dart test/db_bootstrap_test.dart
git commit -m "feat(w1a): first-launch quran.sqlite bootstrap from bundled asset"
```

---

### Task 4: Surah repository + index cubit

**Files:**
- Create: `lib/features/quran/data/surah_repository.dart`, `lib/features/quran/presentation/index/surah_index_state.dart`, `lib/features/quran/presentation/index/surah_index_cubit.dart`, generated `surah_index_state.freezed.dart`
- Modify: `lib/core/di/injector.dart`
- Modify: `pubspec.yaml` via `flutter pub add --dev bloc_test`
- Test: `test/surah_repository_test.dart`, `test/surah_index_cubit_test.dart`

**Interfaces:**
- Produces:
  - `SurahRepository(AppDatabase db)` with `Stream<List<Surah>> watchAll()` — `Surah` = generated drift data class from `app_database.g.dart` (exported via `app_database.dart`).
  - `const SurahIndexState.loading()`, `const SurahIndexState.error(message)`, `const SurahIndexState.loaded({required List<Surah> surahs, String query = ''})` — Freezed sealed union.
  - `SurahIndexCubit(SurahRepository repo)` — holds the latest surah list, registers a drift watch, exposes `void setQuery(String raw)` (trims; empty = all; matches nameAr prefix/contains, nameEn contains, or exact id string).
- DI: `getIt<SurahRepository>()` registered. The cubit is NOT registered in DI — the router constructs it inside a `BlocProvider` (Task 5) so Flutter owns its lifecycle.

- [ ] **Step 1: Deps + failing tests (both files verbatim)**

```powershell
flutter pub add --dev bloc_test
```

`test/surah_repository_test.dart`:
```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';

void main() {
  late AppDatabase db;
  late SurahRepository repo;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    await db.into(db.surahs).insertAll([
      SurahsCompanion.insert(
          id: const Value(1), nameAr: 'الفاتحة', nameEn: 'Al-Fatihah',
          revelationType: 'makkah', ayahCount: 7, pagesStart: 1, pagesEnd: 1),
      SurahsCompanion.insert(
          id: const Value(2), nameAr: 'البقرة', nameEn: 'Al-Baqarah',
          revelationType: 'madinah', ayahCount: 286, pagesStart: 2, pagesEnd: 49),
      SurahsCompanion.insert(
          id: const Value(3), nameAr: 'آل عمران', nameEn: 'Aal-i-Imraan',
          revelationType: 'madinah', ayahCount: 200, pagesStart: 50, pagesEnd: 76),
    ]);
    repo = SurahRepository(db);
  });

  tearDown(() => db.close());

  test('watchAll returns surahs ordered by id', () async {
    final list = await repo.watchAll().first;
    expect(list.map((s) => s.id).toList(), [1, 2, 3]);
  });
}
```

`test/surah_index_cubit_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_state.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    await db.into(db.surahs).insertAll([
      SurahsCompanion.insert(
          id: const Value(1), nameAr: 'الفاتحة', nameEn: 'Al-Fatihah',
          revelationType: 'makkah', ayahCount: 7, pagesStart: 1, pagesEnd: 1),
      SurahsCompanion.insert(
          id: const Value(2), nameAr: 'البقرة', nameEn: 'Al-Baqarah',
          revelationType: 'madinah', ayahCount: 286, pagesStart: 2, pagesEnd: 49),
    ]);
  });

  tearDown(() async => db.close());

  blocTest<SurahIndexCubit, SurahIndexState>(
    'loading then loaded; setQuery filters client-side',
    build: () => SurahIndexCubit(SurahRepository(db)),
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      await cubit.stream.firstWhere((s) => s is SurahIndexLoaded);
      cubit.setQuery('بقرة');
    },
    expect: () => [
      isA<SurahIndexLoading>(),
      isA<SurahIndexLoaded>().having((s) => s.surahs.length, 'surahs', 2),
      isA<SurahIndexLoaded>()
          .having((s) => s.surahs.single.nameAr, 'filtered', 'البقرة')
          .having((s) => s.query, 'query', 'بقرة'),
    ],
  );

  test('whitespace-only query restores the full list', () async {
    final cubit = SurahIndexCubit(SurahRepository(db));
    await Future<void>.delayed(Duration.zero);
    await cubit.stream.firstWhere((s) => s is SurahIndexLoaded);
    cubit.setQuery('البقرة');
    await cubit.stream
        .firstWhere((s) => s is SurahIndexLoaded && s.surahs.length == 1);
    cubit.setQuery(' ');
    await cubit.stream
        .firstWhere((s) => s is SurahIndexLoaded && s.surahs.length == 2);
    await cubit.close();
  });
}
```

- [ ] **Step 2: Run both → FAIL. Then implement the three files (verbatim).**

`lib/features/quran/data/surah_repository.dart`:
```dart
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

class SurahRepository {
  SurahRepository(this._db);

  final AppDatabase _db;

  Stream<List<Surah>> watchAll() {
    final q = _db.select(_db.surahs)
      ..orderBy([(s) => OrderingTerm.asc(s.id)]);
    return q.watch();
  }
}
```

`lib/features/quran/presentation/index/surah_index_state.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/db/app_database.dart';

part 'surah_index_state.freezed.dart';

@freezed
sealed class SurahIndexState with _$SurahIndexState {
  const factory SurahIndexState.loading() = SurahIndexLoading;

  const factory SurahIndexState.loaded({
    @Default(<Surah>[]) List<Surah> surahs,
    @Default('') String query,
  }) = SurahIndexLoaded;

  const factory SurahIndexState.error({required String message}) = SurahIndexError;
}
```

`lib/features/quran/presentation/index/surah_index_cubit.dart`:
```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../data/surah_repository.dart';
import 'surah_index_state.dart';

class SurahIndexCubit extends Cubit<SurahIndexState> {
  SurahIndexCubit(this._repo) : super(const SurahIndexState.loading()) {
    _sub = _repo.watchAll().listen((surahs) {
      _latest = surahs;
      _emitFiltered();
    });
  }

  final SurahRepository _repo;
  final List<Surah> _latest = [];
  String _query = '';
  StreamSubscription<List<Surah>>? _sub;

  void setQuery(String raw) {
    _query = raw.trim();
    _emitFiltered();
  }

  void _emitFiltered() {
    if (isClosed) return;
    emit(SurahIndexState.loaded(surahs: _filter(_latest), query: _query));
  }

  List<Surah> _filter(List<Surah> surahs) {
    if (_query.isEmpty) return surahs;
    final q = _query.toLowerCase();
    return surahs.where((s) {
      return s.nameAr.contains(_query) ||
          s.nameAr.toLowerCase().contains(q) ||
          s.nameEn.toLowerCase().contains(q) ||
          s.id.toString() == _query;
    }).toList();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
```
(Drift's watch re-emits on any table change; `_latest`+`_emitFiltered` keeps a single emit path. Note the first drift event fires `[Surah]` async — hence the tests' `Duration.zero` tick.)

- [ ] **Step 3: Generate + gates**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test test/surah_repository_test.dart test/surah_index_cubit_test.dart
flutter analyze
```
Expected: freezed generated; both files pass; analyze 0 issues.

- [ ] **Step 4: DI — in `lib/core/di/injector.dart` append inside `configureDependencies` (after the AppDatabase registration) + imports:**

```dart
  final db = getIt<AppDatabase>();
  getIt.registerLazySingleton<SurahRepository>(() => SurahRepository(db));
```
```dart
import '../../features/quran/data/surah_repository.dart';
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/quran lib/core/di/injector.dart test/surah_repository_test.dart test/surah_index_cubit_test.dart pubspec.yaml pubspec.lock
git commit -m "feat(w1a): surah repository + index cubit (freezed states, DI, tests)"
```

---

### Task 5: Surah Index screen replacing the `/quran` placeholder

**Files:**
- Create: `lib/features/quran/presentation/index/surah_index_screen.dart`
- Modify: `lib/app/router.dart` (`/quran` route), `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb` (additive-only + regenerate)
- Test: `test/surah_index_screen_test.dart`

**Interfaces:**
- Produces: `const SurahIndexScreen()` — canvas expects an ancestor `BlocProvider<SurahIndexCubit>` (router creates + auto-disposes it; tests supply `BlocProvider.value`). Tap rows: W1b wires navigation (row currently inert).
- l10n keys (additive, both locales): `surahIndexTitle`, `searchSurahHint`, `revelationMakkah`, `revelationMadinah`, `ayatCount(count)`.
- Design contract: D6 tokens via Theme only (no AppColors imports in the screen); Arabic surah names in `QuranFonts.meQuran`; numbers via intl locale formatting (no manual Arabic-Indic conversions).

- [ ] **Step 1: ARB additions (additive ONLY, appended before each file's closing brace)**

AR (`app_ar.arb`):
```json
  "surahIndexTitle": "القرآن الكريم",
  "searchSurahHint": "ابحث بسورة…",
  "revelationMakkah": "مكية",
  "revelationMadinah": "مدنية",
  "ayatCount": "{count} آيات",
  "@ayatCount": { "placeholders": { "count": { "type": "int" } } }
```
EN (`app_en.arb`):
```json
  "surahIndexTitle": "The Noble Quran",
  "searchSurahHint": "Search a surah…",
  "revelationMakkah": "Meccan",
  "revelationMadinah": "Medinan",
  "ayatCount": "{count} verses",
  "@ayatCount": { "placeholders": { "count": { "type": "int" } } }
```

- [ ] **Step 2: Failing widget test FIRST — `test/surah_index_screen_test.dart` (verbatim, BOTH tests inside the same `main()`):**

```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    await db.into(db.surahs).insertAll([
      SurahsCompanion.insert(
          id: const Value(1), nameAr: 'الفاتحة', nameEn: 'Al-Fatihah',
          revelationType: 'makkah', ayahCount: 7, pagesStart: 1, pagesEnd: 1),
      SurahsCompanion.insert(
          id: const Value(2), nameAr: 'البقرة', nameEn: 'Al-Baqarah',
          revelationType: 'madinah', ayahCount: 286, pagesStart: 2, pagesEnd: 49),
      SurahsCompanion.insert(
          id: const Value(3), nameAr: 'النمل', nameEn: 'An-Naml',
          revelationType: 'makkah', ayahCount: 93, pagesStart: 377, pagesEnd: 385),
    ]);
  });

  tearDown(() async => db.close());

  Widget host() => BlocProvider<SurahIndexCubit>(
        create: (_) => SurahIndexCubit(SurahRepository(db)),
        child: const SurahIndexScreen(),
      );

  Future<void> pumpHost(WidgetTester tester) async {
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
      home: host(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('rows render arabic names + counts; search filters live',
      (tester) async {
    await pumpHost(tester);

    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('البقرة'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'بقرة');
    await tester.pumpAndSettle();

    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('الفاتحة'), findsNothing);
  });

  testWidgets('number search narrows by surah id', (tester) async {
    await pumpHost(tester);
    await tester.enterText(find.byType(TextField), '2');
    await tester.pumpAndSettle();
    expect(find.text('البقرة'), findsOneWidget);
    expect(find.text('الفاتحة'), findsNothing);
    expect(find.text('النمل'), findsNothing);
  });
}
```
(Two notes: [1] If the generated AR string renders western digits — `7 آيات` vs `٧ آيات` — flex the WIDGET-TEST digit expectation only, never the app code; asserting Arabic names like above avoids the issue entirely. [2] `بقرة` matches `البقرة` via the cubit's `nameAr.contains` — if this search test fails, re-read the cubit logic; do NOT weaken the test.)

- [ ] **Step 3: Implement the screen — `lib/features/quran/presentation/index/surah_index_screen.dart` (verbatim, complete file):**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'surah_index_cubit.dart';
import 'surah_index_state.dart';

class SurahIndexScreen extends StatelessWidget {
  const SurahIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.surahIndexTitle)),
      body: BlocBuilder<SurahIndexCubit, SurahIndexState>(
        builder: (context, state) => switch (state) {
          SurahIndexLoading() =>
            const Center(child: CircularProgressIndicator()),
          SurahIndexError(:final message) => Center(child: Text(message)),
          SurahIndexLoaded(:final surahs) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    onChanged: context.read<SurahIndexCubit>().setQuery,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: loc.searchSurahHint,
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: surahs.length,
                    itemBuilder: (context, i) => _SurahRow(surah: surahs[i]),
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isMakkah = surah.revelationType == 'makkah';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      onTap: () {
        // W1b: navigate to the reader for this surah.
      },
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          '${surah.id}',
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
      ),
      title: Text(
        surah.nameAr,
        style: const TextStyle(fontFamily: QuranFonts.meQuran, fontSize: 20),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Text(
        '${isMakkah ? loc.revelationMakkah : loc.revelationMadinah} · ${loc.ayatCount(surah.ayahCount)}',
        style: TextStyle(color: colors.onSurfaceVariant),
        textAlign: TextAlign.right,
      ),
      trailing: const Icon(Icons.chevron_left),
    );
  }
}
```
(RTL note: `trailing: chevron_left` gives the mirrored affordance in the RTL list without any transform — Flutter layout stays logical; the icon glyph is directionally chosen here deliberately.)

- [ ] **Step 4: Router — replace the `/quran` line in `lib/app/router.dart` with (verbatim):**

```dart
      GoRoute(
        path: '/quran',
        builder: (_, __) => BlocProvider<SurahIndexCubit>(
          create: (_) => SurahIndexCubit(getIt<SurahRepository>()),
          child: const SurahIndexScreen(),
        ),
      ),
```
+ top-of-file imports:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injector.dart';
import '../features/quran/data/surah_repository.dart';
import '../features/quran/presentation/index/surah_index_cubit.dart';
import '../features/quran/presentation/index/surah_index_screen.dart';
```
(Lifecycle: BlocProvider owns the cubit and closes it on pop; drift watches cancel via cubit.close → repository stays shared through DI.)

- [ ] **Step 5: Gates + commit**

```powershell
flutter gen-l10n
flutter test test/surah_index_screen_test.dart
flutter test
flutter analyze
git add lib/features/quran lib/app/router.dart lib/l10n test/surah_index_screen_test.dart
git commit -m "feat(w1a): surah index screen (l10n, D6 tokens, RTL rows, search)"
```
Expected: analyze 0 issues; ALL tests pass (baseline was 8 — record the new exact total in the report).

---

### Task 6: Close-out

- [ ] **Step 1: Full end gates + artifact proof**

```powershell
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
flutter build apk --debug
git status --porcelain
```
Expected: analyze 0; all tests green (record count); apk exit 0; porcelain empty.

- [ ] **Step 2: Checkbox commit**

```powershell
git add docs/superpowers/plans/2026-10-15-w1a-quran-data-index.md
git commit -m "docs(w1a): mark plan checkboxes complete"
```

- [ ] **Step 3: FINAL REPORT — the PROMPT-1 §8 six-section format, plus: the generated l10n note (which digit set the AR ayatCount produced), APK size, and unpushed count. NO push. WAIT for the PM.**

---

## Self-Review (PM, pre-dispatch)

- **Spec coverage (W1a slice):** §5 seed data (T2) + bootstrap (T3); §3 quran feature layers (T4–T5); offline model step-1 bundle (T2/T3); D6/l10n/i18n-style rules (T5); baseline 8-test suite grows with repo/cubit/widget tests. Reader, mushaf, bookmarks, khatma, pages/juz tabs = W1b (explicit non-goals).
- **Placeholder scan:** none — every code block is complete and final; no fake guards, no TBD/TODO.
- **Type consistency:** `SurahRepository`/`SurahIndexCubit`/`SurahIndexState` names stable across T4 tests, T5 screen/router/test; `Surah` always the drift data class from the single generated file; DI registers only `SurahRepository` (cubit lifecycle owned by BlocProvider — T5 Step 4 rationale box).
- **Errata v2 + v3 applied everywhere:** `Value(...)` id-wrapping (tool + all three test files), `dart:math` min/max, `drift/native.dart` import, public `createSchemaForSeeding()`; `app_database.dart` pure-Dart with required-executor ctor + `LazyDatabase(openAppDatabase)` moved into the injector (W0've 8-test suite must stay green through Task 2 Step 0 gates).
