# S1 Hardening + iOS Readiness — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking. In this repo, execution happens via
> PM-dispatched executor briefs (campaign protocol); each Task below is one dispatchable
> unit with its own commits and gates.

**Goal:** Close the three verified structural gaps (bundled-content freeze, architecture
inversion, missing format gate) and land the near-term iOS code-readiness fixes.

**Architecture:** No rebuild — targeted changes only. Content refresh = versioned re-seed
of two content tables from the bundled asset inside the existing drift DB; deep-link
helpers move from `lib/app/` to `lib/core/utils/` with a new source-scanning guard test;
iOS fixes replicate the installed Flutter 3.47.5 template verbatim.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4 · drift · flutter_bloc · go_router · get_it ·
flutter_local_notifications (22.3.2) · Windows PowerShell 5.1 (no `&&`; use `;`).

**Spec:** `docs/superpowers/specs/2026-10-19-s1-hardening-ios-design.md` (read both).

## Global Constraints

- Repo: `E:\old_flutter\Quran-App-master`, branch `main`. Concurrent sessions are ACTIVE
  (observed HEAD move `0c1e28e`→`6aa2b6b` on 2026-10-19) — tolerate their WIP, never
  touch/stage it.
- Every wave: isolated git **worktree**, verbatim start gate at dispatch (fresh HEAD pin,
  porcelain inventory, unpushed count, `flutter --version`), **NO PUSH**, explicit
  pathspec commits, `git add -A` banned. `.vscode/settings.json` and `INSTRUCTIONS.md`
  are expected debris — never touch/stage/commit.
- Frozen tests: exactly TWO grants for the whole plan — (a) `test/deep_link_routing_test.dart`
  import line (Task 2), (b) the mechanical format pass may touch test files (Task 5,
  format-only; suite counts must stay identical). Any other test edit = STOP and report.
- Gates after every commit: `flutter analyze` → 0 issues; `flutter test` → exact counts,
  pinned at dispatch. Count deltas expected: Task 1 +3 tests, Task 3 +5 tests, others 0.
- Commit messages are English and byte-copied from this plan — NEVER translated.
- Wave order: **W1 = Tasks 1-3** (one executor) · **W2 = Task 4** (one executor) ·
  **W3 = Task 5** (LAST — after W1+W2 land and concurrent sessions settle). W1 and W2 are
  path-disjoint and MAY run in parallel worktrees. W3 strictly after both.

---

### Task 1: Bundled-content version + refresh (spec D1)

**Files:**
- Create: `lib/core/db/content_version.dart`
- Modify: `lib/core/db/app_database.dart` (new helper)
- Modify: `lib/core/db/connection.dart` (refresh call + `ensureContentCurrent`)
- Modify: `tools/build_quran_db.dart` (stamp the version)
- Regenerate: `assets/db/quran.sqlite` (binary)
- Create: `test/content_refresh_test.dart`

**Interfaces:**
- Produces: `kContentVersion` (int), `kContentVersionKey` (String const
  `'content_version'`), `AppDatabase.installedContentVersion() → Future<int>`,
  `ensureContentCurrent(QueryExecutor executor, {required Future<ByteData> Function(String) loadAsset, required Directory tempDir, int bundledVersion = kContentVersion}) → Future<void>`.
- Consumes: existing `copyDbAssetIfAbsent`, `AppDatabase.createSchemaForSeeding()`,
  `rootBundle.load`.

- [ ] **Step 0: Read the generated table names.** In `lib/core/db/app_database.g.dart`
  confirm the SQL table names for `Surahs`, `Ayahs`, `SettingsTable` (expected:
  `surahs`, `ayahs`, `settings_table`). The raw SQL below must use the real names.

- [ ] **Step 1: Write the failing test** — create `test/content_refresh_test.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/connection.dart';
import 'package:quran_yahdi/core/db/content_version.dart';

void main() {
  late Directory tempDir;
  var loaderCalls = 0;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('qy_refresh');
    loaderCalls = 0;
  });
  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<File> buildSeed({required String version, required String nameAr}) async {
    final file = File(p.join(tempDir.path, 'seed.sqlite'));
    final db = AppDatabase(NativeDatabase(file));
    await db.createSchemaForSeeding();
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(1),
          nameAr: nameAr,
          nameEn: 'Seed',
          revelationType: 'meccan',
          ayahCount: 7,
          pagesStart: 1,
          pagesEnd: 1,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(1),
          surahId: 1,
          numberInSurah: 1,
          juz: 1,
          page: 1,
          textUthmani: 'seed',
          textImlaei: 'seed',
        ));
    await db.into(db.settingsTable).insert(
        SettingsTableCompanion.insert(key: kContentVersionKey, value: version));
    await db.close();
    return file;
  }

  Future<ByteData> loaderFor(File seed) async {
    loaderCalls++;
    final bytes = seed.readAsBytesSync();
    return ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
  }

  Future<AppDatabase> staleDb() async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.createSchemaForSeeding();
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(1),
          nameAr: 'قديم',
          nameEn: 'Old',
          revelationType: 'meccan',
          ayahCount: 7,
          pagesStart: 1,
          pagesEnd: 1,
        ));
    return db;
  }

  test('stale installed content is re-seeded; user rows survive; version bumps', () async {
    final seed = await buildSeed(version: '7', nameAr: 'مجدّد');
    final db = await staleDb();
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 1));

    await ensureContentCurrent(db,
        loadAsset: (_) => loaderFor(seed), tempDir: tempDir, bundledVersion: 7);

    expect(loaderCalls, 1);
    expect((await db.select(db.surahs).get()).single.nameAr, 'مجدّد');
    expect((await db.select(db.ayahs).get()).length, 1);
    expect((await db.select(db.bookmarks).get()).length, 1);
    expect(await db.installedContentVersion(), 7);

    await ensureContentCurrent(db,
        loadAsset: (_) => loaderFor(seed), tempDir: tempDir, bundledVersion: 7);
    expect(loaderCalls, 1, reason: 'second call is a no-op');
    await db.close();
  });

  test('a failing loader keeps the previous content and never throws', () async {
    final db = await staleDb();
    await ensureContentCurrent(db,
        loadAsset: (_) => Future<ByteData>.error(StateError('asset missing')),
        tempDir: tempDir,
        bundledVersion: 7);
    expect((await db.select(db.surahs).get()).single.nameAr, 'قديم');
    expect(await db.installedContentVersion(), 0);
    await db.close();
  });

  test('committed asset carries the current content version', () async {
    final copy = File(p.join(tempDir.path, 'asset.sqlite'))
      ..writeAsBytesSync(File('assets/db/quran.sqlite').readAsBytesSync());
    final db = AppDatabase(NativeDatabase(copy));
    expect(await db.installedContentVersion(), kContentVersion);
    await db.close();
  });
}
```

- [ ] **Step 2: Run it to make sure it fails.**
  Run: `flutter test test/content_refresh_test.dart`
  Expected: compile FAIL (`content_version.dart` / `ensureContentCurrent` / `installedContentVersion` not defined).

- [ ] **Step 3: Create `lib/core/db/content_version.dart`:**

```dart
/// Single source of truth for the bundled content version of
/// `assets/db/quran.sqlite`.
///
/// BUMP THIS whenever the asset DB's *content* changes (surah metadata, ayah
/// text/layout fields — i.e. a regenerated quran.sqlite differs). The build
/// tool stamps the value into the asset's settings table; on every open the
/// app compares the installed DB's stamp and re-seeds `surahs`/`ayahs` from
/// the bundled asset when the installed stamp is older. User-owned tables
/// (bookmarks, khatma, prayer log, downloads, installed packs, other
/// settings) are never touched by a refresh.
const int kContentVersion = 1;

/// Row key in the settings table holding the stamped content version.
const String kContentVersionKey = 'content_version';
```

- [ ] **Step 4: Add `installedContentVersion` to `AppDatabase`** (`lib/core/db/app_database.dart`,
  plus `import 'content_version.dart';`):

```dart
  /// The bundled-content version stamped into the installed DB (0 when absent
  /// — pre-versioning installs or a fresh schema). See content_version.dart.
  Future<int> installedContentVersion() async {
    final row = await (select(settingsTable)
          ..where((s) => s.key.equals(kContentVersionKey)))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }
```

- [ ] **Step 5: Add `ensureContentCurrent` to `lib/core/db/connection.dart`** (add
  `import 'dart:developer' as dev;` and `import 'content_version.dart';`), and update
  `openAppDatabase`:

```dart
/// Re-seeds the two content tables (`surahs`/`ayahs`) from the bundled asset
/// when the installed content version is older than [bundledVersion]. User
/// tables are never touched; ayah ids are stable so bookmarks stay valid.
/// Best-effort: a failure logs and keeps the previous content (boot must
/// never crash — house discipline, same class as the reminder boot glue).
@visibleForTesting
Future<void> ensureContentCurrent(
  QueryExecutor executor, {
  required Future<ByteData> Function(String assetKey) loadAsset,
  required Directory tempDir,
  int bundledVersion = kContentVersion,
}) async {
  final db = AppDatabase(executor);
  final installed = await db.installedContentVersion();
  if (installed >= bundledVersion) return;
  final seedFile = File(p.join(tempDir.path, 'quran_yahdi.seed.tmp'));
  try {
    final data = await loadAsset(dbAssetKey);
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await seedFile.writeAsBytes(bytes, flush: true);
    // ATTACH/DETACH cannot run inside a transaction (SQLite rule) — keep them
    // outside; only the row swaps are transactional.
    await db.customStatement('ATTACH DATABASE ? AS seed', [seedFile.path]);
    try {
      await db.transaction(() async {
        await db.customStatement('DELETE FROM ayahs');
        await db.customStatement('DELETE FROM surahs');
        await db.customStatement('INSERT INTO surahs SELECT * FROM seed.surahs');
        await db.customStatement('INSERT INTO ayahs SELECT * FROM seed.ayahs');
        // INSERT OR REPLACE, not upsert syntax: API 24 devices ship an old
        // system SQLite where ON CONFLICT DO UPDATE is unavailable.
        await db.customStatement(
          'INSERT OR REPLACE INTO settings_table(key, value) VALUES (?, ?)',
          [kContentVersionKey, '$bundledVersion'],
        );
      });
    } finally {
      await db.customStatement('DETACH DATABASE seed');
    }
  } on Object catch (error, stackTrace) {
    dev.log('content refresh failed',
        name: 'quran_yahdi/db', error: error, stackTrace: stackTrace);
  } finally {
    if (seedFile.existsSync()) seedFile.deleteSync();
  }
}

Future<QueryExecutor> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'quran_yahdi.sqlite'));
  await copyDbAssetIfAbsent(
    target: file,
    assetKey: dbAssetKey,
    loadAsset: rootBundle.load,
  );
  final executor = NativeDatabase.createInBackground(
    file,
    setup: (database) {
      database.execute('PRAGMA journal_mode = WAL;');
      database.execute('PRAGMA synchronous = NORMAL;');
    },
  );
  await ensureContentCurrent(executor,
      loadAsset: rootBundle.load, tempDir: dir);
  return executor;
}
```

  (Keep the existing pragma setup block exactly; the sketch above only shows placement.)

- [ ] **Step 6: Stamp the version in `tools/build_quran_db.dart`** — add
  `import 'package:quran_yahdi/core/db/content_version.dart';` and, after the seeding
  batch and before the count check:

```dart
  await db.into(db.settingsTable).insertOnConflictUpdate(
        SettingsTableCompanion.insert(
          key: kContentVersionKey,
          value: '$kContentVersion',
        ),
      );
```

- [ ] **Step 7: Regenerate the asset and verify.**
  Run: `dart run tools/build_quran_db.dart`
  Expected output: `surahs=114 ayahs=6236 bytes=...` (a `Running build hooks...` stderr
  line is known noise and is ignored).

- [ ] **Step 8: Run the tests to green.**
  Run: `flutter test test/content_refresh_test.dart` then the full `flutter test`.
  Expected: new file 3/3 PASS; full suite = dispatch baseline + 3, EXIT 0.

- [ ] **Step 9: Gates + commit.**
  Run: `flutter analyze` (0) and `flutter test` (exact count).
  Commit (explicit pathspec):
  `git add lib/core/db/content_version.dart lib/core/db/app_database.dart lib/core/db/connection.dart tools/build_quran_db.dart assets/db/quran.sqlite test/content_refresh_test.dart`
  `git commit -m "feat(db): content-version stamp + bundled-content refresh on app update (S1)"`

---

### Task 2: Deep-links move to `core/utils` (spec D2)

**Files:**
- Create: `lib/core/utils/deep_links.dart` (content moved verbatim from `lib/app/deep_links.dart`)
- Delete: `lib/app/deep_links.dart`
- Modify: `lib/main.dart` (import), `lib/features/quran/presentation/reader/reader_screen.dart` (import)
- Modify (GRANTED): `test/deep_link_routing_test.dart` — the single import line only

**Interfaces:** unchanged public API (`deepLinkHost`, `deepLinkRouteFor`, `webSurahUrl`);
same library-level doc comment, updated to say "lives in core so both `app/` boot code and
features can depend on it without inverting layering".

- [ ] **Step 1: Move the file.** Create `lib/core/utils/deep_links.dart` with the exact
  content of `lib/app/deep_links.dart` (verify last: `rg -n "deep_links" lib test` lists
  exactly main.dart, reader_screen.dart, the test — update all three; then delete
  `lib/app/deep_links.dart`).
- [ ] **Step 2: Run the affected tests.**
  Run: `flutter test test/deep_link_routing_test.dart test/reader_share_affordance_test.dart` → PASS.
- [ ] **Step 3: Full gates + commit.**
  `flutter analyze` 0; `flutter test` = baseline count (delta 0).
  Commit: `git add lib/core/utils/deep_links.dart lib/main.dart lib/features/quran/presentation/reader/reader_screen.dart test/deep_link_routing_test.dart`
  (stage the deletion too: `git add -u lib/app/deep_links.dart` if needed by pathspec rules)
  `git commit -m "refactor(core): move deep-link mapping to core/utils — no feature imports app/ (S1)"`

---

### Task 3: Architecture guard test (spec D2)

**Files:**
- Create: `test/architecture_guard_test.dart`

**Interfaces:** pure test file; no production code. Constants:
`allowedFeatureEdges` (the pinned set of 8); helpers `resolveTarget`, `featureOf`, `edgeOf`.

- [ ] **Step 1: Write the test** (failing only if a violation exists — it should pass on
  the post-Task-2 tree; the synthetic-resolver test is the TDD unit):

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Pinned cross-feature edges — every entry is a DELIBERATE dependency.
/// Adding an edge here is an architecture decision; do not grow silently.
/// PM ruling 2026-10-19: the guard's first run caught three PRE-EXISTING edges
/// the hand-built pin had missed (a scanner bug) — ratified and added below.
const Set<String> allowedFeatureEdges = {
  'home->prayer',
  'home->quran',
  'duas->quran',
  'quran->recitation',
  'quran->library',
  'qibla->prayer',
  'prayer->notifications',
  'settings->notifications',
  'notifications->prayer',
  'notifications->tracker',
  'settings->prayer',
};

/// Scans import AND export directives — a cross-feature dependency can hide in
/// a re-export just as easily as in an import (PM ruling 2026-10-19).
final _importRe = RegExp(r"(?:import|export)\s+'([^']+)'");

/// Resolves an import target to a `lib/`-relative posix path; null for
/// non-local (dart:/foreign package) imports.
String? resolveTarget(String fileRel, String import) {
  if (import.startsWith('package:quran_yahdi/')) {
    return 'lib/${import.substring('package:quran_yahdi/'.length)}';
  }
  if (import.startsWith('dart:') || import.startsWith('package:')) return null;
  if (!import.startsWith('.')) return null;
  return p.posix.normalize(p.posix.join(p.posix.dirname(fileRel), import));
}

String? featureOf(String libRel) =>
    RegExp(r'^lib/features/([a-z_]+)/').firstMatch(libRel)?.group(1);

(String, String)? edgeOf(String fromRel, String toRel) {
  final from = featureOf(fromRel);
  final to = featureOf(toRel);
  if (from == null || to == null || from == to) return null;
  return (from, to);
}

void main() {
  final sources = <String, String>{};
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    if (f.path.endsWith('.g.dart') || f.path.endsWith('.freezed.dart')) continue;
    final rel = p.posix.joinAll(p.split(f.path)); // lib/... with / separators
    sources[rel] = f.readAsStringSync();
  }

  test('the scan actually reads the tree', () {
    expect(sources.length, greaterThan(100));
  });

  test('resolver handles package, relative, and foreign imports', () {
    expect(
        resolveTarget('lib/features/a/x.dart',
            'package:quran_yahdi/core/db/app_database.dart'),
        'lib/core/db/app_database.dart');
    expect(
        resolveTarget('lib/features/a/presentation/x.dart',
            '../../../core/utils/a.dart'),
        'lib/core/utils/a.dart');
    expect(resolveTarget('lib/features/a/x.dart', 'dart:async'), isNull);
    expect(resolveTarget('lib/features/a/x.dart', 'package:flutter/material.dart'),
        isNull);
  });

  test('no feature imports the app layer', () {
    final offenders = <String>[];
    sources.forEach((rel, src) {
      if (!rel.startsWith('lib/features/')) return;
      for (final m in _importRe.allMatches(src)) {
        final target = resolveTarget(rel, m.group(1)!);
        if (target != null && target.startsWith('lib/app/')) {
          offenders.add('$rel -> ${m.group(1)}');
        }
      }
    });
    expect(offenders, isEmpty,
        reason: 'features must not depend on lib/app/ — move shared logic to core/');
  });

  test('cross-feature edges stay within the pinned allowlist', () {
    final offenders = <String>[];
    sources.forEach((rel, src) {
      if (!rel.startsWith('lib/features/')) return;
      for (final m in _importRe.allMatches(src)) {
        final target = resolveTarget(rel, m.group(1)!);
        if (target == null) continue;
        final edge = edgeOf(rel, target);
        if (edge == null) continue;
        if (!allowedFeatureEdges.contains('${edge.\$1}->${edge.\$2}')) {
          offenders.add('$rel -> ${m.group(1)} [${edge.\$1}->${edge.\$2}]');
        }
      }
    });
    expect(offenders, isEmpty,
        reason: 'new cross-feature dependency — add it to allowedFeatureEdges '
            'consciously in this test, or remove the import');
  });

  test('feature data layers stay Flutter-free', () {
    final offenders = <String>[];
    sources.forEach((rel, src) {
      if (!RegExp(r'^lib/features/[a-z_]+/data/').hasMatch(rel)) return;
      if (_importRe
          .allMatches(src)
          .any((m) => m.group(1) == 'package:flutter/material.dart')) {
        offenders.add(rel);
      }
    });
    expect(offenders, isEmpty,
        reason: 'data-layer files must not import flutter/material');
  });
}
```

  NOTE: in the real file write `edge.$1` / `edge.$2` (no backslash) — the backslashes
  above exist only to survive this plan's markdown.

- [ ] **Step 2: Run it.**
  Run: `flutter test test/architecture_guard_test.dart` → 5/5 PASS. If the edge test
  fails, the failing edge list is a real finding — do NOT widen the allowlist without a
  PM ruling; report it.
- [ ] **Step 3: Full gates + commit.**
  `flutter analyze` 0; `flutter test` = baseline + 3 (Task 1) + 5 (this file).
  Commit: `git add test/architecture_guard_test.dart`
  `git commit -m "test(arch): guard features→app, cross-feature edges, and data-layer purity (S1)"`

---

### Task 4: iOS near-term readiness (spec D4) — W2

Pre-step (once): generate the reference scaffold from the installed SDK:
`flutter create --platforms=ios --project-name refscaffold "C:\Users\ASUS\AppData\Local\Temp\opencode\qy_ios_ref"`
Use it as the byte-source for template files; never hand-type template content.

- [ ] **Step 4a: Icon alpha (P0-1).** `pubspec.yaml`: add `remove_alpha_ios: true` under
  `flutter_launcher_icons`; run `dart run flutter_launcher_icons`. Verify with the
  LockBits scan (fast) that `minAlpha >= 1` on
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`; verify
  `git status --porcelain` shows only `pubspec.yaml` + `ios/**` icon files.
  Commit: `git add pubspec.yaml ios/Runner/Assets.xcassets`
  `git commit -m "chore(ios): remove alpha from App Store icon (P0-1, S1-ios)"`

- [ ] **Step 4b: Notifications iOS wiring (P1-1/P1-2/P1-3).** Read
  `lib/features/notifications/data/notifications_binding.dart` fully, then:
  (1) `InitializationSettings` gains
  `iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false)`
  (permissions requested explicitly later — keeps the Android boot-grace semantics);
  (2) `ensurePermissions` gains the iOS branch after the Android one:
  `final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>(); if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;`
  (3) `ios/Runner/AppDelegate.swift`: assign `UNUserNotificationCenter.current().delegate`
  in `didFinishLaunchingWithOptions` — copy the exact snippet from the
  `flutter_local_notifications` iOS setup section in the pub cache
  (`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_local_notifications-*\README.md`),
  adapted to the current template shape. Exact class/method names MUST come from the
  pub-cache source, not from memory.
  Gates: `flutter analyze` 0 + full tests (delta 0; existing notification tests green).
  Commit: `git add lib/features/notifications/data/notifications_binding.dart ios/Runner/AppDelegate.swift`
  `git commit -m "feat(ios): local-notifications iOS wiring — init settings, permission path, UNUserNotificationCenter delegate (P1-1/P1-2/P1-3, S1-ios)"`

- [ ] **Step 4c: Bundle id (P1-5).** In `ios/Runner.xcodeproj/project.pbxproj` replace
  every `com.example.quranApp` with `com.mostafasayed.quranyahdi` (RunnerTests ids derive
  from the same prefix). Verify: `rg -ni "com\.example" ios` → 0 hits;
  `rg -n "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj` → 6 hits, all
  the new id.
  Commit: `git add ios/Runner.xcodeproj/project.pbxproj`
  `git commit -m "chore(ios): bundle id com.mostafasayed.quranyahdi (+RunnerTests) (P1-5, S1-ios)"`

- [ ] **Step 4d: Template sync (P1-4/P1-6/P2-1).** Diff the reference scaffold against
  `ios/` and apply, verbatim:
  (1) `IPHONEOS_DEPLOYMENT_TARGET = 12.0` → `15.0` (3 sites in `project.pbxproj`) +
  `ios/Flutter/AppFrameworkInfo.plist` `MinimumOSVersion` → `15.0`;
  (2) UIScene adoption: copy `SceneDelegate.swift` from the reference, add its
  `PBXFileReference`/`PBXBuildFile`/group/sources-phase entries to `project.pbxproj`
  mirroring the reference, add `UIApplicationSceneManifest` to `Info.plist` and align
  `AppDelegate.swift` with the reference (window property moves to SceneDelegate);
  (3) `Info.plist` `CFBundleDisplayName` → `قرآن يَهدي`.
  Verify: `rg -n "12\.0" ios/Runner.xcodeproj/project.pbxproj ios/Flutter/AppFrameworkInfo.plist`
  → 0 hits; SceneDelegate wiring present ≥4 times; `flutter analyze` 0; full tests delta 0.
  DISCLOSE: no Mac on this machine — compile proof is deferred to the first Mac session
  (`flutter build ios --no-codesign`); this commit lands code-readiness only.
  Commit: `git add ios/Runner.xcodeproj/project.pbxproj ios/Flutter/AppFrameworkInfo.plist ios/Runner/Info.plist ios/Runner/AppDelegate.swift ios/Runner/SceneDelegate.swift`
  `git commit -m "chore(ios): template sync — deployment target 15.0, UIScene lifecycle, Arabic display name (P1-4/P1-6/P2-1, S1-ios)"`

---

### Task 5: Format pass + CI gate (spec D3) — W3, LAST

- [ ] **Step 5a: Pin the pre-change set and prove format-only.** Capture
  `dart format --output=none --set-exit-if-changed lib test tools` (expect exit 1) and
  save the changed-file list (dispatch-time snapshot; ~49 files on 2026-10-19, drift with
  concurrent sessions is expected). Then run `dart format lib test tools`; re-run the
  check → exit 0. Run `flutter analyze` (0) and `flutter test` (count must equal the
  dispatch baseline — format-only). Scope check: `git status --porcelain` shows exactly
  the pinned set (+ owner debris, untouched, never staged).
  Commit: `git add -- <the exact pinned list>`
  `git commit -m "style: repo-wide dart format pass over lib test tools — mechanical (S1)"`
  PROOF NOTE: do not offer `git diff -w` as the purity proof (line reflow makes it
  meaningless); the proof is formatter canonicality (re-check exit 0) + identical test
  counts + `flutter analyze` 0, and 0 generated files were affected (verified 2026-10-19).

- [ ] **Step 5b: Gate it in CI.** `.github/workflows/ci.yml`, step after `flutter analyze`:
  `- run: dart format --output=none --set-exit-if-changed lib test tools`
  Commit: `git add .github/workflows/ci.yml`
  `git commit -m "ci: gate dart format (set-exit-if-changed) over lib test tools (S1)"`

- [ ] **Step 5c: Final wave gates.** `flutter analyze` 0 + full `flutter test` (exact
  count), then report: per-commit SHA/stat, pinned changed-file list vs actual, counts,
  porcelain, unpushed count. NO PUSH.

---

## Self-Review (completed inline)

- **Spec coverage:** D1→Task 1 · D2→Tasks 2-3 · D3→Task 5 · D4→Task 4 (P0-1, P1-1..6,
  P2-1) · D5 = decision only (no code) · D6 = Global Constraints. Deferrals match spec §3.
- **Placeholders:** none; every step carries exact code/commands/paths; the only
  "verify at source" instructions (generated table names, plugin API names, reference
  scaffold) are deliberate source-of-truth pins, each with the exact command.
- **Type consistency:** `kContentVersion`/`kContentVersionKey` single-sourced; helpers
  `ensureContentCurrent` / `installedContentVersion` used identically in code, tests, and
  commit messages; guard-test helper names consistent within the file.
