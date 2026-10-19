# S1 Structural Hardening + iOS Near-Term Readiness — Design Spec

Date: 2026-10-19 · Status: APPROVED by owner (GO 2026-10-19) — W1 landed; iOS wave in progress
Prepared by: PM session (Mode B artifact — English, per standing rule)

Source state: architecture review observed HEAD `0c1e28e` on 2026-10-19; verification
subagents saw concurrent commits land up to `6aa2b6b` (ACTIVE parallel sessions — every
wave re-pins its start gate at dispatch time).

## 1. Why this spec

A full system-design/architecture review (2026-10-19, read-only) compared `quran_yahdi`
against the official Flutter architecture guidance, the BLoC architecture, the Flutter
offline-first design pattern, and OSS Quran-app peers (mhmzdev/the-holy-quran-app,
SadaqaWorks/Quran-Flutter, aqeelshamz/quran).

**Verdict: no rebuild.** The as-built structure (feature-first + cubit/freezed + drift +
go_router + get_it + l10n/ARB) matches the official recommendations; dependency direction
is clean (zero cycles; few, deliberate cross-feature edges); DIP seams exist where they
pay (`AyahSource`, `SurahSource`, `LastReadSource`, `ReciterSource`, `CatalogSource`,
`PlaybackService`, `ReminderScheduler`). A rebuild would discard a CI-green, 440+-test,
release-ready codebase for zero architectural gain.

This spec covers the owner-approved follow-ups: **S1 structural hardening**, the **iOS
near-term readiness wave**, and the **crash-visibility decision (D-crash)**.

## 2. Verified findings (evidence)

- **F1 — Bundled content is frozen after first install.** `copyDbAssetIfAbsent`
  (`lib/core/db/connection.dart:13-23`) copies `assets/db/quran.sqlite` only when the
  target is absent (`:18` `if (target.existsSync()) return;` — the sole guard; no
  hash/size/version compare). Sole production call site: `openAppDatabase` (`:28`).
  Repo-wide, no content-version tracking exists (zero hits for
  `user_version|contentVersion|content_version|reseed` in `lib/ tools/ test/`). The asset
  DB's SQLite `user_version` = 2 — that is **drift's schema stamp** (equal to
  `app_database.dart:26 schemaVersion => 2`), NOT a content marker. `tools/build_quran_db.dart`
  deletes + rebuilds the asset and stamps nothing content-related. Conclusion: an app
  update shipping a corrected/updated `quran.sqlite` (v1.1+) leaves existing installs on
  the old `surahs`/`ayahs` content **forever**; `onUpgrade` (`app_database.dart:30-33`)
  only creates schema. (Verified by an independent read-only subagent + PM read of both files.)
- **F2 — One features→app inversion.** Exactly one import of the app layer from within
  `lib/features/**`: `lib/features/quran/presentation/reader/reader_screen.dart:7`
  (`import '../../../../app/deep_links.dart';`). No other cases. No import guard exists.
- **F3 — No format gate; format-red tree.** `.github/workflows/ci.yml` has no
  `dart format` step. `dart format --output=none --set-exit-if-changed lib test tools`
  → exit 1, 49 files would reflow (snapshot 2026-10-19; heap includes `lib/` 11 files,
  `test/` 36 files, `tools/` 2 files). **0 of the 49 are generated** (`.g.dart`/
  `.freezed.dart` are format-clean → a CI gate will not fight `build_runner`).
  `integration_test/` does not exist; no `matchesGoldenFile` anywhere.
- **F4 — iOS: all P0/P1 from the 2026-10-17 audit still open.** Re-verified at HEAD
  `0c1e28e`→`6aa2b6b`; zero `ios/**` commits since the audit. Still-open: P0-1 (icon
  alpha), P1-1/P1-2/P1-3 (notifications dead on iOS — no iOS init settings, no iOS
  permission path, no `UNUserNotificationCenter` delegate), P1-4 (deployment target 12.0
  vs template 15.0 / plugins 13.0), P1-5 (`PRODUCT_BUNDLE_IDENTIFIER = com.example.quranApp`),
  P1-6 (no UIScene), P1-7 (no macOS CI — strong-to-have, not a store blocker without a Mac).
  Since the audit: P2-9 fixed (`800849d`); P2-10 deferred by design (W7c locale un-pin).
- **F5 — Crash-reporting research (2026-10-19).** Play Console Android vitals gives crash
  clusters + stack traces + ANRs + pre-launch device reports **with zero SDK and zero app
  telemetry**, provided (a) R8 `mapping.txt` is uploaded per release, (b) native debug
  symbols ship for native frames; Dart frames of `--obfuscate` builds need a local
  `flutter symbolize` (Play cannot ingest Flutter SYMBOLS). What Vitals cannot see: errors
  caught by `FlutterError.onError` (most Dart defects), non-fatals, breadcrumbs, logs;
  daily lag; sparse data at low volume; Android-only. Adding any SDK (Crashlytics
  default-on; Sentry PII-off/EU/self-host) would falsify the current Data-Safety "NO
  collection" answer (`docs/store/data-safety-form-answers.md`) and the PRIVACY.md
  absolute («لا نجمع أي بيانات عنك، إطلاقًا»). Sources: support.google.com/googleplay
  (9844486, 9859174, 9848633, 10787469), developer.android.com Google Play vitals crash,
  docs.flutter.dev/testing/errors + deployment/obfuscate, firebase.google.com Crashlytics
  privacy, docs.sentry.io Flutter data-collected + data-storage-location.

## 3. Decisions

### D1 — Content-package refresh (fixes F1)

- **Version marker:** `lib/core/db/content_version.dart` exports
  `kContentVersion` (int) and `kContentVersionKey = 'content_version'`. Rule (documented
  in the file): **bump `kContentVersion` whenever `assets/db/quran.sqlite` content
  changes.**
- **Stamp:** `tools/build_quran_db.dart` writes `kContentVersion` into the asset DB's
  `settings_table` after seeding (imports the same constant → single source of truth).
  The regenerated asset is committed with this wave.
- **Refresh:** `openAppDatabase` keeps `copyDbAssetIfAbsent` unchanged, then calls a new
  `ensureContentCurrent(executor, loadAsset, tempDir)` (in `connection.dart`,
  `@visibleForTesting`): read `installedContentVersion()` (new helper on `AppDatabase`,
  0 when absent); if `installed >= kContentVersion` → no-op; else write the asset bytes
  to `<dir>/quran_yahdi.seed.tmp`, `ATTACH` it (outside any transaction — SQLite rule),
  and inside one transaction `DELETE FROM surahs/ayahs` + `INSERT ... SELECT * FROM
  seed.surahs/seed.ayahs` + upsert the `content_version` row; `DETACH`; delete temp.
- **Invariants:** user tables (`bookmarks`, `khatma_progress`, `prayer_log`, `downloads`,
  `installed_packs`, `settings_table` rows other than the version key) are never touched.
  Ayah IDs are stable (1..6236) so bookmarks stay valid. Indexes live on the main DB and
  survive row swaps. Failure mode: best-effort — log via `dev.log` (house discipline,
  same class as the reminder boot glue) and keep previous content; boot never crashes.
- **Behavior matrix:** fresh install → copied asset already carries the current stamp →
  no-op. Pre-versioning install → one harmless re-seed. Future content bump → exactly one
  refresh on first open after update.

### D2 — Deep-links relocation + architecture guard (fixes F2)

- Move `deepLinkHost`, `deepLinkRouteFor`, `_ayahFromFragment`, `webSurahUrl` verbatim to
  **`lib/core/utils/deep_links.dart`** (pure Dart, zero Flutter imports — unchanged
  property). Delete `lib/app/deep_links.dart`. Update importers: `lib/main.dart`,
  `reader_screen.dart`, and the single import line in
  `test/deep_link_routing_test.dart` (**explicit owner grant required** — frozen-test rule).
- New **`test/architecture_guard_test.dart`** (source-scanning test, house "test-as-policy"
  style) with three assertions over `lib/`:
  1. No `lib/features/**` file imports the app layer (allowlist: empty).
  2. Cross-feature import/export edges ⊆ the pinned allowlist of the 11 deliberate edges
     ratified 2026-10-19 — the guard's first run caught three PRE-EXISTING edges a
     hand-built matrix had missed (`notifications→prayer`, `notifications→tracker`,
     `settings→prayer`), now pinned alongside: `home→prayer`, `home→quran`, `duas→quran`,
     `quran→recitation`, `quran→library`, `qibla→prayer`, `prayer→notifications`,
     `settings→notifications`. New edges must be added to the test consciously.
  3. No `lib/features/**/data/**` file imports `flutter/material` (today: true; keeps the
     data layer UI-free).
  Scanner resolves relative + `package:quran_yahdi/` imports with `path.posix`; the test
  also unit-tests the resolver on synthetic inputs and sanity-checks that >100 source
  files were scanned (guards against a silently broken scan).

### D3 — Format pass + CI gate (fixes F3)

- One mechanical `dart format lib test tools` pass, committed alone
  (`style(...)` — format-only). Proof of purity: formatter canonicality (re-check exits 0),
  zero generated files affected (verified), `flutter analyze` 0, full test suite counts
  **identical** to the dispatch baseline. (NOT `git diff -w` — line-reflow makes that
  proof inadequate, per standing lesson.)
- Then add to `.github/workflows/ci.yml` (after `flutter analyze`):
  `dart format --output=none --set-exit-if-changed lib test tools`.
- Ordering: **last** — it must run after every other wave (and after concurrent sessions
  settle) so it captures the final texture of the tree.

### D4 — iOS near-term readiness wave (fixes F4 must-fix set)

Scope = code-side readiness; verification on Windows = `flutter analyze` + full tests +
diff review; **compile/run verification requires the first Mac session** (FLAG-1/2 remain
owner-gated). Changes:

1. **P0-1**: `remove_alpha_ios: true` in `pubspec.yaml` (`flutter_launcher_icons`) +
   regenerate iOS icons; verify decoded `Icon-App-1024x1024@1x.png` minAlpha ≥ 1.
2. **P1-1/P1-2/P1-3**: iOS notifications wiring in `notifications_binding.dart`
   (`DarwinInitializationSettings` with permissions left **unrequested at init**,
   explicit `requestPermissions` in `ensurePermissions` via the iOS plugin branch — keeps
   the Android boot-grace semantics) + `AppDelegate.swift` assigns
   `UNUserNotificationCenter.current().delegate` (canonical Flutter template pattern).
   Exact plugin API names verified against the pub-cache source of
   `flutter_local_notifications` at implementation time.
3. **P1-5**: bundle id → `com.mostafasayed.quranyahdi` (+ `…RunnerTests`) in
   `project.pbxproj`.
4. **P1-4 + P1-6 + P2-1** (one "iOS project template sync" commit): deployment target
   12.0 → 15.0 (`project.pbxproj` ×3 + `AppFrameworkInfo.plist`), UIScene lifecycle
   (`SceneDelegate.swift` + `UIApplicationSceneManifest` in `Info.plist` + AppDelegate
   window removal), `CFBundleDisplayName` → `قرآن يَهدي`. Source of truth for template
   files: a reference scaffold generated on this machine with
   `flutter create --platforms=ios` from the installed Flutter 3.47.5 SDK — copied
   verbatim, not hand-typed.

Deferred (must NOT be pulled into this wave): P1-7 macOS CI job (strong-to-have; revisit
at the first Mac session), P2-2/P2-4/P2-5/P2-6/P2-7/P2-8 (cheap polish; P2-6 Podfile
materializes on first Mac `pod install`), P2-10 (stays with W7c locale un-pin), universal
links (future IOS wave per `2026-10-18-p4-app-links.md`).

### D5 — Crash visibility: zero-SDK (researched verdict, owner asked for the right call)

**Adopted for v1: remain zero-telemetry.** Field visibility comes from **Play Console
Android vitals** (no SDK, no app code) plus its pre-launch reports; deployment checklist:
upload R8 `mapping.txt` per release; ship native debug symbols
(`ndk.debugSymbolLevel = 'FULL'`); archive Flutter symbols when/if `--split-debug-info`
is introduced. Optional (cheap, post-v1, keeps every promise literally true): a bounded
local diagnostics ring buffer (`FlutterError.onError` / `PlatformDispatcher.onError` →
file) with a user-initiated "Share diagnostics" button (reuses the existing `share_plus`)
— nothing leaves the device unless the user shares. If an SDK is ever adopted, prefer
**Sentry** (EU residency / self-host, `sendDefaultPii=false` defaults, consent-first init)
in opt-in mode — but that flips the Data-Safety "NO collection" answer and the PRIVACY
absolute, so it requires an explicit future owner decision plus a policy/data-safety
re-answer. Honest tradeoff accepted: Dart-level caught errors and breadcrumbs will be
invisible in v1.

### D6 — Execution protocol under concurrent sessions

- Every wave runs in an **isolated git worktree**, with a verbatim start gate at dispatch
  (fresh HEAD pin, expected porcelain = owner debris + tolerated session WIP at dispatch
  time, unpushed count, toolchain). Trunk is `main`; **NO PUSH** — pushes only in an
  owner-GO window. Explicit pathspec commits; `git add -A` banned.
- Frozen tests: exactly **two** grants for this entire spec — (a) `test/deep_link_routing_test.dart`
  import line (D2), (b) the mechanical format pass may touch test files (D3, format-only,
  counts must stay identical). Anything else = STOP and report.
- Wave order: **W1 = D1+D2+guard** (one executor, 4 commits) → **W2 = D4** (one executor,
  4 commits) → **W3 = D3** (format + CI, last). W1 and W2 touch disjoint paths
  (`lib/** test/** tools/** assets/db/**` vs `pubspec.yaml ios/**`) and MAY run in
  parallel worktrees if the owner wants speed; W3 strictly after both.

## 4. Explicit non-goals

Full rebuild · package split / melos · imposed domain layers · `Result<T>` rework · any
telemetry SDK (D5) · cloud backup · iOS store publish (readiness only) · boot receiver for
reminders (accepted v1 risk, revisit post-store) · goldens/integration tests (S3 growth
options, separate future decision).

## 5. Open for owner

1. Ratify **D5** (zero-SDK; recommended) — or direct otherwise.
2. Grant the two frozen-test exceptions in D6.
3. Execution scheduling: dispatch W1+W2 now (parallel worktrees allowed) with W3 after —
   or one sequential executor for all three.
4. iOS publish timing (Apple account / Mac availability) — affects when W2's code gets
   its compile proof.
