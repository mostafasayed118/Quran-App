# Quran Yahdi — Wave 2a (Recitation Catalog + Offline Downloads) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Ship the recitation catalog: ALL 243 reciters (mp3quran API, cached in drift v2), featured-above-list ordering from PM-verified ids, per-surah mp3 downloads into app storage with a sequential queue, live statuses — playable catalog ready for the W2b playback wave.

**Architecture:** `ReciterRepository` (network → drift cache, pure Dart) → `AudioDownloader` (dio stream → file, statuses in the W0 `downloads` table) → `DownloadsCubit` (sequential queue, singleton) → two screens (reciters list + surah list). NO audio playback in this wave (W2b owns `just_audio`).

**Tech Stack:** W0/W1 stack ONLY — `dio` and `http` already present. **Zero new packages.**

**Spec:** `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md`. Ledger lessons binding.

## Global Constraints

- Binding rules (all waves): analyze ends 0 issues; TDD red→green where stated; explicit-pathspec commits with these exact messages; NO push; checkbox ticks committed at close-out; one writer on `main`.
- **PM-verified facts (2026-10-15, mp3quran API v3 dump):** 243 reciters; featured (reciterId, moshafId) pairs = عبدالباسط 51/53 · العفاسي 123/123 · الحصري 118/118 · الدوسري 92/92 · المعيقلي 102/102 · السديس 54/54 · الغامدي 30/30 · الشاطري 4/4 · العجمي 5/5 (all حفص مرتل, 114 surahs). Featured ids are EMBEDDED as verified constants — never fabricate/extend them.
- Companion signature lesson: read `lib/core/db/app_database.g.dart` AFTER build_runner and BEFORE writing anything that uses a new companion. Text-PK precedent (`SettingsTable`): `required String key` (NOT Value). Integer explicit-PK precedent (`Surahs`): `Value` wrapped. VERIFY, do not assume.
- Data-layer files (`lib/features/recitation/data/**`) stay pure Dart (no flutter imports). DI/injector must stay importable by pure-VM tests (S7 lesson): anything needing path_provider lives in the screen/cubit layer or an injected closure.
- Frozen-test edit (PM-granted, intent-preserving): `test/db_migration_test.dart` asserts `allTables.length == 8` — this wave makes it **9** (new `reciters` table). Update that ONE number (and only it) with a one-line disclosure.
- Network tests use a local ephemeral `HttpServer` — real IO, no mocks, plain `test()` (never widget/FakeAsync).
- L10n: additive keys only, both locales.

---

### Task 1: Start gate

- [x] **Step 1: Record verbatim**

```powershell
git rev-parse --short=7 HEAD; git status --porcelain; flutter --version
```
Expected: HEAD `7cb37bd` or later with intervening commits touching ONLY `docs/`; porcelain empty; branch `main`. Else STOP.

---

### Task 2: Schema v2 — `reciters` table + migration

**Files:**
- Modify: `lib/core/db/tables.dart` (append Reciters), `lib/core/db/app_database.dart` (register + version + migration)
- Modify: `assets/db/quran.sqlite` (RERUN the W1a tool — asset becomes v2) + `tools/chapters_cache.json` unchanged
- Modify: `test/db_migration_test.dart` (8 → 9, PM-granted)
- Generated: `lib/core/db/app_database.g.dart` (rerun)

**Interfaces:**
- Produces: `@DataClassName('ReciterRow')` table `Reciters` (id TEXT PK = `"$reciterId-$moshafId"`, reciterName, moshafName, server, surahList TEXT, surahTotal INT); `schemaVersion = 2`; upgradefrom v1 creates only missing tables.
- IMPORTANT drift migration note: `{Reciters}` must be added to the `@DriftDatabase(tables: [...])` list too, else onUpgrade create misses it.

- [x] **Step 1: Append to `lib/core/db/tables.dart`**

```dart
@DataClassName('ReciterRow')
class Reciters extends Table {
  TextColumn get id => text()(); // "reciterId-moshafId"
  TextColumn get reciterName => text()();
  TextColumn get moshafName => text()();
  TextColumn get server => text()();
  TextColumn get surahList => text()(); // "1,2,3,..."
  IntColumn get surahTotal => integer()();
  @override
  Set<Column> get primaryKey => {id};
}
```
NOTE: `@DataClassName` needs NO new import (it is a drift annotation via the existing import).

- [x] **Step 2: Edit `lib/core/db/app_database.dart`** — add `Reciters,` to the `@DriftDatabase(tables: [...])` list, set `schemaVersion` to `2`, and add:
```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createAll();
          }
        },
      );
```
(`MigrationStrategy` arrives via the existing `package:drift/drift.dart` import.)

- [x] **Step 3: Frozen-test granted edit — in `test/db_migration_test.dart` change ONLY the count assertion `expect(db.allTables.length, 8)` → `expect(db.allTables.length, 9)` with a trailing comment `// w2a: + reciters (PM grant)`.**

- [x] **Step 4: Regenerate + extend the test file with a reciters CRUD probe (add ONE test, verbatim)**

```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
```
already present — now append inside `main()`:
```dart
  test('v2 adds reciters table; companion roundtrips a row', () async {
    final db2 = AppDatabase.test(NativeDatabase.memory());
    await db2.into(db2.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'https://server11.mp3quran.net/basit/',
            surahList: '1,2,3',
            surahTotal: 114,
          ),
        );
    final row = await db2.select(db2.reciters).getSingle();
    expect(row.id, '51-53');
    expect(row.surahTotal, 114);
    await db2.close();
  });
```
MANDATORY VERIFICATION STEP before this compiles confidently: after `dart run build_runner build`, OPEN `app_database.g.dart` and locate `RecitersCompanion.insert` — CONFIRM which params are `required` vs `Value(...)`. If `id` differs from `required String` (text-PK precedent), disclose + adjust ALL usages in this plan accordingly (single-token fixes, W1b acceptance class).

- [x] **Step 5: Rebuild the bundled asset (v2) + gates + commit**

```powershell
dart run build_runner build --delete-conflicting-outputs
dart run tools/build_quran_db.dart
flutter test test/db_migration_test.dart
flutter analyze
git add lib/core/db test/db_migration_test.dart assets/db/quran.sqlite
git commit -m "feat(w2a): drift schema v2 (reciters catalog table) + rebuilt bundle"
```

---

### Task 3: ReciterRepository (+ URL/parse pure helpers) + DI

**Files:**
- Create: `lib/features/recitation/data/reciter_repository.dart`
- Modify: `lib/core/di/injector.dart`
- Test: `test/reciter_repository_test.dart`

**Interfaces:**
- Produces:
  - `String surahAudioUrl(String server, int surahNumber)` + `String surahAudioFileName(int surahNumber)` (pure; `000`-padded, single trailing slash guaranteed).
  - `List<int> parseSurahList(String csv)` (pure; trims, drops unparsable).
  - `List<ReciterRow> sortReciters(List<ReciterRow> input)` (pure — featured first in the verified order [51,123,118,92,102,54,30,4], then alphabetical by reciterName).
  - `ReciterRepository(AppDatabase db, {http.Client? client})`:
    - `Future<void> refreshFromApi()` — GET `https://mp3quran.net/api/v3/reciters?language=ar`; wipe + batch-insert all moshaf rows (replace-all semantics).
    - `Stream<List<ReciterRow>> watchAll()` — live, unsorted (sorting applied by callers via `sortReciters`).
    - `Future<ReciterRow?> byId(String rowId)`.
    - `Future<void> selectMoshaf(String rowId)` / `Future<String?> loadSelectedMoshaf()` — settings key `selected_moshaf_row` (plain `key:` — settings text-PK precedent).
- DI: `ReciterRepository` singleton (client default real; tests pass `IOClient` or rely on the local-server override pattern below).

- [x] **Step 1: Failing tests — `test/reciter_repository_test.dart` (verbatim)**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';

const fixture = '''
{"reciters":[
 {"id":51,"name":"عبدالباسط عبدالصمد","letter":"ع","moshaf":[
   {"id":53,"name":"حفص عن عاصم - مرتل","server":"https://server11.example.net/basit/","surah_total":114,"surah_list":"1,2,3"},
   {"id":51,"name":"المصحف المجود","server":"https://server11.example.net/mujawwad/","surah_total":114,"surah_list":"1,2"}]},
 {"id":123,"name":"مشاري العفاسي","letter":"م","moshaf":[
   {"id":123,"name":"حفص عن عاصم - مرتل","server":"https://server8.example.net/afs/","surah_total":114,"surah_list":"2,1"}]}
]}
''';

void main() {
  late AppDatabase db;
  late ReciterRepository repo;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = ReciterRepository(db);
  });

  tearDown(() async => db.close());

  test('pure helpers: url building + parse + featured sort', () {
    expect(surahAudioFileName(2), '002.mp3');
    expect(surahAudioFileName(114), '114.mp3');
    expect(surahAudioUrl('https://srv.net/afs/', 1),
        'https://srv.net/afs/001.mp3');
    expect(surahAudioUrl('https://srv.net/afs', 1),
        'https://srv.net/afs/001.mp3');
    expect(parseSurahList(' 1, 2 ,x,3 '), [1, 2, 3]);

    final sorted = sortReciters([
      _row(id: '123-123', name: 'مشاري العفاسي'),
      _row(id: '55-55', name: 'أحمد العجمي'),
      _row(id: '51-53', name: 'عبدالباسط عبدالصمد'),
      _row(id: '4-4', name: 'الشاطري'),
    ]);
    expect(sorted.map((r) => r.id).toList(),
        ['51-53', '4-4', '123-123', '55-55']);
  });

  test('refreshFromApi wipes + inserts moshaf rows (local server)', () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.write(fixture);
      await req.response.close();
    });
    addTearDown(() async => server.close(force: true));

    final hosted =
        'http://127.0.0.1:${server.port}/api/v3/reciters?language=ar';
    final netRepo = ReciterRepository(
      db,
      client: http.Client(),
      apiEndpointOverride: hosted,
    );
    await netRepo.refreshFromApi();

    final rows = await db.select(db.reciters).get();
    expect(rows, hasLength(3));
    final basit = rows.firstWhere((r) => r.id == '51-53');
    expect(basit.reciterName, 'عبدالباسط عبدالصمد');
    expect(parseSurahList(basit.surahList), [1, 2, 3]);

    // Idempotent re-run: still 3 rows, no dupes.
    await netRepo.refreshFromApi();
    expect(await db.select(db.reciters).get(), hasLength(3));
  });

  test('selection persists + loads', () async {
    expect(await repo.loadSelectedMoshaf(), isNull);
    await repo.selectMoshaf('51-53');
    expect(await repo.loadSelectedMoshaf(), '51-53');
  });
}

ReciterRow _row({required String id, required String name}) => ReciterRow(
      id: id,
      reciterName: name,
      moshafName: 'مرتل',
      server: 'https://x/',
      surahList: '1',
      surahTotal: 114,
    );
```

- [x] **Step 2: Run → FAIL. Implement `lib/features/recitation/data/reciter_repository.dart` (verbatim)**

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../../core/db/app_database.dart';

/// Featured reciters pinned by PM from the verified 2026-10-15 mp3quran dump
/// (all حفص مرتل, 114 surahs each). Never extend without a PM grant.
const List<int> featuredReciterIds = <int>[
  51, 123, 118, 92, 102, 54, 30, 4, 5,
];

String surahAudioFileName(int surahNumber) =>
    '${surahNumber.toString().padLeft(3, '0')}.mp3';

String surahAudioUrl(String server, int surahNumber) {
  final base =
      server.endsWith('/') ? server : '$server/';
  return '$base${surahAudioFileName(surahNumber)}';
}

List<int> parseSurahList(String csv) => csv
    .split(',')
    .map((part) => int.tryParse(part.trim()))
    .whereType<int>()
    .toList();

List<ReciterRow> sortReciters(List<ReciterRow> input) {
  var featuredRank = 0;
  final ranks = <int, int>{};
  for (final id in featuredReciterIds) {
    ranks[id] = featuredRank;
    featuredRank += 1;
  }
  int rankOf(ReciterRow row) {
    final leadingId = int.tryParse(row.id.split('-').first);
    final featured = leadingId == null ? null : ranks[leadingId];
    return featured ?? featuredReciterIds.length;
  }

  final sorted = [...input]..sort((a, b) {
      final byFeature = rankOf(a).compareTo(rankOf(b));
      if (byFeature != 0) return byFeature;
      final byName = a.reciterName.compareTo(b.reciterName);
      if (byName != 0) return byName;
      return a.id.compareTo(b.id);
    });
  return sorted;
}

const recitersApiEndpoint = 'https://mp3quran.net/api/v3/reciters?language=ar';
const selectedMoshafKey = 'selected_moshaf_row';

class ReciterRepository {
  ReciterRepository(
    this._db, {
    http.Client? client,
    String? apiEndpointOverride,
  })  : _client = client ?? http.Client(),
        _endpoint = apiEndpointOverride ?? recitersApiEndpoint;

  final AppDatabase _db;
  final http.Client _client;
  final String _endpoint;

  Future<void> refreshFromApi() async {
    final res = await _client.get(Uri.parse(_endpoint));
    if (res.statusCode != 200) {
      throw StateError('mp3quran HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final reciters = (data['reciters'] as List).cast<Map<String, dynamic>>();
    final rows = <RecitersCompanion>[];
    for (final reciter in reciters) {
      final reciterId = (reciter['id'] as num).toInt();
      final reciterName = (reciter['name'] ?? '') as String;
      final moshafs =
          (reciter['moshaf'] as List? ?? const []).cast<Map<String, dynamic>>();
      for (final moshaf in moshafs) {
        final moshafId = (moshaf['id'] as num).toInt();
        rows.add(RecitersCompanion.insert(
          id: '$reciterId-$moshafId',
          reciterName: reciterName,
          moshafName: (moshaf['name'] ?? '') as String,
          server: (moshaf['server'] ?? '') as String,
          surahList: (moshaf['surah_list'] ?? '') as String,
          surahTotal: (moshaf['surah_total'] as num?)?.toInt() ?? 0,
        ));
      }
    }
    await _db.delete(_db.reciters).go();
    await _db.batch((b) => b.insertAll(_db.reciters, rows));
  }

  Stream<List<ReciterRow>> watchAll() => _db.select(_db.reciters).watch();

  Future<ReciterRow?> byId(String rowId) =>
      (_db.select(_db.reciters)..where((r) => r.id.equals(rowId)))
          .getSingleOrNull();

  Future<void> selectMoshaf(String rowId) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: selectedMoshafKey,
            value: rowId,
          ),
        );
  }

  Future<String?> loadSelectedMoshaf() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(selectedMoshafKey)))
        .getSingleOrNull();
    return row?.value;
  }
}
```
NOTE at top of file (add): `import 'dart:convert';` for `jsonDecode`.
VERIFICATION (Errata-lesson, mandatory): after `build_runner`, open `app_database.g.dart` → `RecitersCompanion.insert`. Text-PK precedent says `required String id` (plain) — the code above assumes EXACTLY that. If the generated signature differs, adjust ONLY these usages, disclose in the report.

- [x] **Step 3: DI — append inside `configureDependencies`:**

```dart
  getIt.registerLazySingleton<ReciterRepository>(() => ReciterRepository(db));
```
```dart
import '../../features/recitation/data/reciter_repository.dart';
```

- [x] **Step 4: Gates + commit**

```powershell
flutter test test/reciter_repository_test.dart
flutter analyze
git add lib/features/recitation/data lib/core/di/injector.dart test/reciter_repository_test.dart
git commit -m "feat(w2a): reciter repository (mp3quran cache, featured sort, selection)"
```

---

### Task 4: AudioDownloader + sequential queue cubit

**Files:**
- Create: `lib/features/recitation/data/audio_downloader.dart`
- Create: `lib/features/recitation/presentation/downloads/downloads_cubit.dart`, `lib/features/recitation/presentation/downloads/downloads_state.dart` (+ generated `.freezed.dart`)
- Modify: `lib/core/di/injector.dart` (register downloader with an injected audio-root closure + queue singleton)
- Test: `test/audio_downloader_test.dart`, `test/downloads_cubit_test.dart`

**Interfaces:**
- `AudioDownloader(AppDatabase db, {Dio? dio, Future<Directory> Function()? audioRootResolver})`:
  - `Future<File> downloadSurah({required ReciterRow reciter, required int surahNumber, void Function(int received, int total)? onProgress})` — gold path: status row `downloading` → dio stream to `audio/<reciterId>/<NNNN>.mp3` → row `done` (+bytes); any failure: row `failed`, target deleted, rethrow.
  - `Future<void> removeDownload({required ReciterRow reciter, required int surahNumber})`.
  - `Future<bool> isDownloaded(String rowId, int surahNumber)` — `done` row AND file exists.
  - `Future<String?> downloadedPath(String rowId, int surahNumber)`.
- `DownloadsCubit({required AudioDownloader downloader, required ReciterRepository reciters})`:
  - state `DownloadsState(items: Map<String, DownloadItem>)` keyed `'$rowId-$surah'`; `DownloadItem {String status; int received; int total;}` (freezed data class).
  - `Future<void> enqueue(String rowId, int surahNumber)` — dedupes active/done, appends to queue, drains SEQUENTIALLY.
  - `Future<void> refreshDone()` — on first subscribe-ready load, hydrate `done` items from the DB rows.
- DI: closures pattern — `AudioDownloader(db, audioRootResolver: () async => (await getApplicationSupportDirectory()).`audio` Folder)` — NO: injector must stay flutter-free (S7). The resolver closure is provided from `main.dart` at startup:
  `await configureDependencies(audioRootResolver: defaultAudioRootResolver);` where `defaultAudioRootResolver` lives in `lib/app/bootstrap.dart` (imports path_provider; app-layer = flutter-allowed). `configureDependencies({Future<Directory> Function()? audioRootResolver})` — if null, downloader registration is SKIPPED and re-attempted by `ensureAudioBindings(audioRootResolver)` called from main BEFORE runApp; W0 `injector_test` never calls audio bits (still passes on the VM).
- APPROVED detail: `Queue drain failure = mark failed + continue next task` (never throw out of the drain loop).

- [x] **Step 1: Failing tests — `test/audio_downloader_test.dart` (verbatim — local ephemeral server pattern)**

```dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late HttpServer server;
  late String base;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    tempRoot = await Directory.systemTemp.createTemp('qy_audio_test');
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'PLACEHOLDER',
            surahList: '1,2',
            surahTotal: 114,
          ),
        );
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
    await db.close();
  });

  Future<AudioDownloader> serve(
    void Function(HttpRequest request) handler,
  ) async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) => handler(req));
    base = 'http://127.0.0.1:${server.port}/';
    final row = await (db.select(db.reciters)).getSingle();
    final updated = row.copyWith(server: base);
    await (db.update(db.reciters)..where((r) => r.id.equals(row.id)))
        .write(RecitersCompanion(server: Value(updated.server)));
    return AudioDownloader(
      db,
      dio: Dio(),
      audioRootResolver: () async => tempRoot,
    );
  }

  tearDown(() {
    if (server != null) {
      server.close(force: true);
    }
  });

  test('download streams to file, reports progress, marks done', () async {
    final downloader = await serve((req) async {
      req.response.add(List<int>.generate(4096, (i) => i % 251));
      await req.response.close();
    });
    final reciter =
        await (db.select(db.reciters)).getSingle();
    final receivedTotal = <List<int>>[];
    final file = await downloader.downloadSurah(
      reciter: reciter,
      surahNumber: 2,
      onProgress: (received, total) => receivedTotal.add([received, total]),
    );

    expect(file.existsSync(), isTrue);
    expect(await file.length(), 4096);
    expect(receivedTotal, isNotEmpty);
    final statuses = await (db.select(db.downloads)
          ..where((d) => d.reciterId.equals('51-53')))
        .get();
    expect(statuses.single.status, 'done');
    expect(statuses.single.bytes, 4096);
    expect(await downloader.isDownloaded('51-53', 2), isTrue);
  });

  test('server 404 marks failed and removes the partial file', () async {
    final downloader = await serve((req) async {
      req.response.statusCode = 404;
      await req.response.close();
    });
    final reciter = await (db.select(db.reciters)).getSingle();

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DioException>()),
    );

    final statuses = await (db.select(db.downloads)
          ..where((d) => d.reciterId.equals('51-53')))
        .get();
    expect(statuses.single.status, 'failed');
    expect(await downloader.isDownloaded('51-53', 1), isFalse);
  });
}
```

- [x] **Step 2: Failing queue test — `test/downloads_cubit_test.dart` (verbatim)**

```dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_state.dart';

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    tempRoot = await Directory.systemTemp.createTemp('qy_queue_test');
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'PLACEHOLDER',
            surahList: '1,2,3',
            surahTotal: 114,
          ),
        );
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
    await db.close();
  });

  test('enqueue drains strictly sequentially and marks done', () async {
    final order = <String>[];
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) {
      order.add(req.uri.path);
      req.response.add(List<int>.filled(64, 1));
      req.response.close();
    });
    addTearDown(() async => server.close(force: true));

    final base = 'http://127.0.0.1:${server.port}/';
    await (db.update(db.reciters)).write(RecitersCompanion(server: Value(base)));
    final repo = ReciterRepository(db);
    final downloader = AudioDownloader(
      db,
      dio: Dio(),
      audioRootResolver: () async => tempRoot,
    );
    final cubit = DownloadsCubit(downloader: downloader, reciters: repo);
    addTearDown(cubit.close);

    await cubit.enqueue('51-53', 1);
    await cubit.enqueue('51-53', 2);
    await cubit.stream.firstWhere((s) =>
        s.items['51-53-1']?.status == 'done' &&
        s.items['51-53-2']?.status == 'done');

    expect(order, ['/001.mp3', '/002.mp3'],
        reason: 'queue is strictly sequential');
  });

  test('failed task does not stall the queue', () async {
    var failNext = true;
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      if (failNext) {
        failNext = false;
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      req.response.add(List<int>.filled(32, 1));
      await req.response.close();
    });
    addTearDown(() async => server.close(force: true));

    final base = 'http://127.0.0.1:${server.port}/';
    await (db.update(db.reciters)).write(RecitersCompanion(server: Value(base)));
    final repo = ReciterRepository(db);
    final downloader = AudioDownloader(
      db,
      dio: Dio(),
      audioRootResolver: () async => tempRoot,
    );
    final cubit = DownloadsCubit(downloader: downloader, reciters: repo);
    addTearDown(cubit.close);

    await cubit.enqueue('51-53', 1); // will fail
    await cubit.enqueue('51-53', 2); // must still complete
    await cubit.stream.firstWhere((s) =>
        s.items['51-53-1']?.status == 'failed' &&
        s.items['51-53-2']?.status == 'done');
  });
}
```

- [x] **Step 3: Run all four → FAIL. Implement (verbatim).**

`lib/features/recitation/data/audio_downloader.dart`:
```dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'reciter_repository.dart';

class DownloadFailure implements Exception {
  DownloadFailure(this.message);

  final String message;
  @override
  String toString() => 'DownloadFailure: $message';
}

class AudioDownloader {
  AudioDownloader(
    this._db, {
    Dio? dio,
    Future<Directory> Function()? audioRootResolver,
  })  : _dio = dio ?? Dio(),
        _audioRoot = audioRootResolver;

  final AppDatabase _db;
  final Dio _dio;
  final Future<Directory> Function()? _audioRoot;

  static const audioFolderName = 'audio';

  Future<Directory> _root() async {
    final resolver = _audioRoot;
    if (resolver != null) return resolver();
    throw DownloadFailure(
        'audioRootResolver not configured — call ensureAudioBindings() first');
  }

  Future<File> _targetFile(String rowId, int surahNumber) async {
    final rootDir = await _root();
    final folder = Directory(
        '${rootDir.path}${Platform.pathSeparator}$audioFolderName${Platform.pathSeparator}$rowId');
    await folder.create(recursive: true);
    return File(
        '${folder.path}${Platform.pathSeparator}${surahAudioFileName(surahNumber)}');
  }

  Future<void> _markStatus(
      String rowId, int surahNumber, String status, int bytes, String path) async {
    final existing = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) & d.surahId.equals(surahNumber)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.downloads).insert(DownloadsCompanion.insert(
            reciterId: rowId,
            surahId: surahNumber,
            status: status,
            path: path,
            bytes: Value(bytes),
          ));
    } else {
      await (_db.update(_db.downloads)
            ..where((d) => d.id.equals(existing.id)))
          .write(DownloadsCompanion(
        status: Value(status),
        bytes: Value(bytes),
        path: Value(path),
      ));
    }
  }

  Future<File> downloadSurah({
    required ReciterRow reciter,
    required int surahNumber,
    void Function(int received, int total)? onProgress,
  }) async {
    final target = await _targetFile(reciter.id, surahNumber);
    final url = surahAudioUrl(reciter.server, surahNumber);
    await _markStatus(reciter.id, surahNumber, 'downloading', 0, target.path);
    try {
      final res = await _dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
      );
      final total =
          int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? '') ?? 0;
      var received = 0;
      final sink = target.openWrite();
      try {
        await for (final chunk in res.data!.cast<List<int>>()) {
          received += chunk.length;
          sink.add(chunk);
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      final size = await target.length();
      await _markStatus(reciter.id, surahNumber, 'done', size, target.path);
      return target;
    } on Object {
      await _markStatus(reciter.id, surahNumber, 'failed', 0, target.path);
      if (await target.exists()) {
        await target.delete();
      }
      rethrow;
    }
  }

  Future<bool> isDownloaded(String rowId, int surahNumber) async {
    final row = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) &
              d.surahId.equals(surahNumber) &
              d.status.equals('done')))
        .getSingleOrNull();
    if (row == null) return false;
    return File(row.path).exists();
  }

  Future<String?> downloadedPath(String rowId, int surahNumber) async {
    if (!await isDownloaded(rowId, surahNumber)) return null;
    final row = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) & d.surahId.equals(surahNumber)))
        .getSingleOrNull();
    return row?.path;
  }

  Future<void> removeDownload(String rowId, int surahNumber) async {
    final row = await (_db.select(_db.downloads)
          ..where((d) =>
              d.reciterId.equals(rowId) & d.surahId.equals(surahNumber)))
        .getSingleOrNull();
    if (row != null) {
      final f = File(row.path);
      if (await f.exists()) await f.delete();
      await (_db.delete(_db.downloads)..where((d) => d.id.equals(row.id))).go();
    }
  }

  /// All completed-download rows (used by the queue cubit on startup).
  Future<List<Download>> listDone() =>
      (_db.select(_db.downloads)..where((d) => d.status.equals('done'))).get();
}
```
(imports it additionally needs: `surahAudioFileName`/`surahAudioUrl` from `reciter_repository.dart` — add `import 'reciter_repository.dart';`.)

`lib/features/recitation/presentation/downloads/downloads_state.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'downloads_state.freezed.dart';

@freezed
sealed class DownloadItem with _$DownloadItem {
  const factory DownloadItem({
    @Default('queued') String status,
    @Default(0) int received,
    @Default(0) int total,
  }) = _DownloadItem;
}

@freezed
sealed class DownloadsState with _$DownloadsState {
  const factory DownloadsState({
    @Default(<String, DownloadItem>{}) Map<String, DownloadItem> items,
  }) = _DownloadsState;
}
```

`lib/features/recitation/presentation/downloads/downloads_cubit.dart`:
```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../data/audio_downloader.dart';
import '../../data/reciter_repository.dart';
import 'downloads_state.dart';

class DownloadsCubit extends Cubit<DownloadsState> {
  DownloadsCubit({
    required AudioDownloader downloader,
    required ReciterRepository reciters,
  })  : _downloader = downloader,
        _reciters = reciters,
        super(const DownloadsState());

  final AudioDownloader _downloader;
  final ReciterRepository _reciters;
  final List<(String, int)> _queue = <(String, int)>[];
  bool _draining = false;

  String _key(String rowId, int surahNumber) => '$rowId-$surahNumber';

  Future<void> refreshDone() async {
    final rows = await _downloader.listDone();
    var items = state.items;
    for (final row in rows) {
      final key = '${row.reciterId}-${row.surahId}';
      items = {...items, key: const DownloadItem(status: 'done')};
    }
    if (isClosed) return;
    emit(state.copyWith(items: items));
  }

  Future<void> enqueue(String rowId, int surahNumber) async {
    final key = _key(rowId, surahNumber);
    final current = state.items[key];
    if (current != null &&
        (current.status == 'downloading' || current.status == 'done')) {
      return;
    }
    if (_queue.any((task) => task.$1 == rowId && task.$2 == surahNumber)) return;
    _queue.add((rowId, surahNumber));
    emit(state.copyWith(
      items: {
        ...state.items,
        key: const DownloadItem(status: 'queued'),
      },
    ));
    await _drain();
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty && !isClosed) {
        final (rowId, surahNumber) = _queue.first;
        _queue.removeAt(0);
        final key = _key(rowId, surahNumber);
        final reciter = await _reciters.byId(rowId);
        if (reciter == null) {
          await _setFailed(key);
          continue;
        }
        if (isClosed) return;
        emit(_bump(key, status: 'downloading'));
        try {
          await _downloader.downloadSurah(
            reciter: reciter,
            surahNumber: surahNumber,
            onProgress: (received, total) {
              if (isClosed) return;
              emit(_bump(key, status: 'downloading', received: received, total: total));
            },
          );
          if (isClosed) return;
          emit(_bump(key, status: 'done'));
        } on Object {
          if (isClosed) return;
          await _setFailed(key);
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _setFailed(String key) async {
    // The failed status in the DB is owned by the downloader; mirror in state.
    emit(_bump(key, status: 'failed'));
  }

  DownloadsState _bump(String key, {required String status, int received = 0, int total = 0}) {
    final current = state.items[key] ?? const DownloadItem();
    return state.copyWith(
      items: {
        ...state.items,
        key: current.copyWith(status: status, received: received, total: total),
      },
    );
  }
}
```
(listDone() already ships inside the AudioDownloader class above.)dart
  Future<List<Download>> listDone() =>
      (_db.select(_db.downloads)..where((d) => d.status.equals('done'))).get();
```

- [x] **Step 4: DI (bootstrap split, S7-safe)**

`lib/core/di/injector.dart` — accept the resolver and register ONLY when provided:
```dart
Future<void> configureDependencies({
  Future<Directory> Function()? audioRootResolver,
}) async {
  ...
  if (audioRootResolver != null) {
    getIt.registerLazySingleton<AudioDownloader>(
        () => AudioDownloader(db, audioRootResolver: audioRootResolver));
    getIt.registerLazySingleton<DownloadsCubit>(
        () => DownloadsCubit(
            downloader: getIt<AudioDownloader>(),
            reciters: getIt<ReciterRepository>()));
  }
}
```
imports there: `dart:io` (Directory) + recitation data + presentation cubit + `package:drift/drift.dart` NOT needed. `Future<Directory>` via dart:io ✓ pure-VM safe.
`lib/app/bootstrap.dart` NEW file:
```dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> defaultAudioRootResolver() async {
  final dir = await getApplicationSupportDirectory();
  return dir;
}
```
`lib/main.dart` — replace `await configureDependencies();` with:
```dart
import 'app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(audioRootResolver: defaultAudioRootResolver);
  runApp(const QuranYahdiApp());
}
```
W0 injector_test unchanged (`configureDependencies()` with no resolver still legal; its `AppDatabase` path stays identical).

- [x] **Step 5: Gates + commit**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test test/audio_downloader_test.dart test/downloads_cubit_test.dart
flutter analyze
git add lib/features/recitation lib/core/di/injector.dart lib/app/bootstrap.dart lib/main.dart test/audio_downloader_test.dart test/downloads_cubit_test.dart
git commit -m "feat(w2a): audio downloader + sequential queue (dio streams, drift statuses)"
```

---

### Task 5: Reciters screen (+ route replaces `/recitations`, l10n)

**Files:**
- Create: `lib/features/recitation/presentation/reciters/reciters_cubit.dart`, `reciters_state.dart` (+freezed), `reciters_screen.dart`
- Modify: `lib/app/router.dart` (`/recitations` replaces its placeholder), l10n AR/EN additive
- Test: `test/reciters_screen_test.dart`

**Interfaces:**
- `RecitersCubit({required ReciterRepository repo})` — state: `loading` → `ready(reciters, query)` → error; `refresh()` calls `refreshFromApi()` then live re-emits via `watchAll()`; `setQuery(String)`.
- Route: `/recitations` → `BlocProvider(create: RecitersCubit(getIt<ReciterRepository>()))`.

- [x] **Step 1: l10n additive (AR)**
```json
  "recitationsTitle": "التلاوات",
  "searchReciters": "ابحث عن قارئ…",
  "featured": "مختارات",
  "allReciters": "كل القرّاء",
  "noReciters": "حمّل فهرس القرّاء من الإنترنت",
  "refresh": "تحديث",
  "surahCountLabel": "{count} سورة",
  "@surahCountLabel": { "placeholders": { "count": { "type": "String" } } }
```
EN:
```json
  "recitationsTitle": "Recitations",
  "searchReciters": "Search a reciter…",
  "featured": "Featured",
  "allReciters": "All reciters",
  "noReciters": "Load the reciters index from the internet",
  "refresh": "Refresh",
  "surahCountLabel": "{count} surahs",
  "@surahCountLabel": { "placeholders": { "count": { "type": "String" } } }
```

- [x] **Step 2: Implement cubit + state + screen** (state/implementations mirror W1a screen patterns exactly — sealed freezed loading/ready/error, FutureBuilder-free, `watchAll()` feed, `sortReciters` applied on ready, query-filtered by reciterName/moshafName contains, refresh button wired to `refresh()` with try/catch into an error banner). Screen rows: ornate initial letter, `reciterName` (`QuranFonts.ui` 16 bold), subtitle `moshafName`, trailing `surahTotal.toArabicIndic` + label; taps: `context.push('/recitations/reciter?row=${Uri.encodeComponent(row.id)}')`; a one-time `refresh()` kick on init when the underlying list is empty (offline-first: cached list shows instantly; the kick is a soft network refresh — failures land in a snack-bar, never a dead screen).

- [x] **Step 3: Widget tests — `test/reciters_screen_test.dart` (2 tests, teardown-safe, verbatim shape):** a `_StaticReciterRepository extends ReciterRepository` with `watchAll() => Stream.value(seeded rows: '51-53' عبدالباسط + '55-55' تجربة)`; assert featured row appears FIRST (find.text('عبدالباسط عبدالصمد') at a LOWER Y offset than the other name), search field narrows to 1 row on 'عفاسي', error-free no-reciters state shows `noReciters` text with an unstyled empty list.

- [x] **Step 4: Router — REPLACE the `/recitations` placeholder GoRoute:**
```dart
      GoRoute(
        path: '/recitations',
        builder: (_, __) => BlocProvider<RecitersCubit>(
          create: (_) =>
              RecitersCubit(repo: getIt<ReciterRepository>()),
          child: const RecitersScreen(),
        ),
      ),
```
imports as needed.

- [x] **Step 5: Gates + commit**

```powershell
flutter gen-l10n
flutter test test/reciters_screen_test.dart
flutter analyze
git add lib/features/recitation lib/app/router.dart lib/l10n test/reciters_screen_test.dart
git commit -m "feat(w2a): reciters catalog screen (search, featured-first, refresh)"
```

---

### Task 6: Reciter's surah list + download actions

**Files:**
- Create: `lib/features/recitation/presentation/reciter_surahs/reciter_surahs_cubit.dart`, `reciter_surahs_state.dart` (+freezed), `reciter_surahs_screen.dart`
- Modify: `lib/app/router.dart` (`/recitations/reciter?row=`)
- Test: `test/reciter_surahs_screen_test.dart`

**Interfaces:**
- `ReciterSurahsCubit({required ReciterRepository reciters, required AyahRepository? no — surah names come from a new small method: ADD to Task-3 repo? NO — ADD here: `SurahNamesFor` in ReciterRepository via `_db.select(_db.surahs)..where isIn` returning `Map<int, String>`; produces `ready(row, surahNumbers, names map, items map from DownloadsCubit passthrough)`; enqueue/delete delegate to DownloadsCubit (pulled via getIt in the ROUTE BlocProvider chain — DownloadsCubit is a singleton; PROVIDE it as inherited `BlocProvider.value` in the route).
- Route: `/recitations/reciter?row=` → wraps BOTH `DownloadsCubit.value(getIt<DownloadsCubit>())` + `BlocProvider(create: ReciterSurahsCubit(...))`.

- [x] **Step 1: Failing tests — `test/reciter_surahs_screen_test.dart` (2 tests, verbatim shape):** teardown-safe `_StaticReciterRepository` + `_StaticDownloader(downloaderStream fixed done/queued statuses)`; route-host pumps `MultiBlocProvider`; test A: rows render 'الم' + 'ذلك الكتاب' texts + names الفاتحة/البقرة from a names map; test B: tapping the download icon on surah 1 calls enqueue (the static wraps a mutable flag); no real network anywhere.

- [x] **Step 2: Implement the three files** — screen layout per approved mock 6: app-bar = reciterName + moshafName + set-default action (star icon → `selectMoshaf` + golden snackbar `تم تعيينه قارئك الافتراضي`), rows: ornate Arabic-Indic number, surah name (from names map, fallback `سورة N`), then a status widget column driven by the DownloadsState map: `done` → checks + gold bookmark border, `downloading` → `(received/total)` label + LinearProgressIndicator, `failed` → red retry icon, default → download icon. All download/delete actions delegate to `context.read<DownloadsCubit>()` (enqueue/removeDownload + refreshDone on init).
- [x] **Step 3: Add to Task-3 repo (one method, l10n-clean):**
```dart
  Future<Map<int, String>> surahNamesFor(List<int> surahIds) async {
    if (surahIds.isEmpty) return {};
    final rows = await (_db.select(_db.surahs)
          ..where((s) => s.id.isIn(surahIds)))
        .get();
    return {for (final s in rows) s.id: s.nameAr};
  }
```
- [x] **Step 4: Gates + commit**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test test/reciter_surahs_screen_test.dart
flutter analyze
git add lib/features/recitation lib/app/router.dart test/reciter_surahs_screen_test.dart
git commit -m "feat(w2a): reciter surahs screen (per-surah downloads, statuses, default reciter)"
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
Expected: analyze 0; all pass — baseline 28, expect ≈ 36 (record exact); apk exit 0 + bytes; porcelain empty; deps current/no discontinued.

- [x] **Step 2: Checkbox commit**

```powershell
git add docs/superpowers/plans/2026-10-15-w2a-reciters-downloads.md
git commit -m "docs(w2a): mark plan checkboxes complete"
```

- [x] **Step 3: FINAL REPORT — PROMPT-2 §8 format + the g.dart companion-signature verification transcript + the downloaded table row lifecycle (downloading→done/failed count) + APK size + unpushed count. NO PUSH. WAIT — W2b belongs to the PM.**

---

## Explicit non-goals (this wave)

Playback (W2b just_audio + facade + mini player + reader hook + media notification), deletion-UI polish, khatma-audio queue, iOS manifest work (iOS paths untouched), Supabase manifest (W6).

## Self-Review (PM, pre-dispatch)

- Spec coverage: D9/D10 offline-first downloads + catalog; §5 `reciters` table + downloads table lifecycle; D10 (mp3quran only, zero egress); wrapper order for serialization. Playback and its player-bar UI live strictly in W2b.
- The single frozen-test edit (`8` → `9`) is PM-granted here.
- All code blocks final; no debris tokens; no test-helper deps; widget tests steer clear of live drift watches (teardown-safe overrides shipped inline).
