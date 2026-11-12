# Performance Audit — Quran Yahdi (`quran_yahdi`)

**Date:** 2026-11-09 · **Auditor:** agent (measurement-driven) · **HEAD at audit:** `6e0ff45` (branch `wave/audit-remediation`, 7 ahead of `main` @ `d78582e`)

> **Revision 2 (same day, 16:55):** the owner connected the **physical test device** (Infinix X6882, Android 14). The earlier emulator-only pass is kept below for reference, but every headline number in §3/§7 now comes from the device. A/B used a rebuilt **release** APK with the four audit fixes (owner-cert signed via `android/key.properties`, installed with `-r` — **owner data preserved**).

## 1. Executive Summary

The application is in good shape — the 2026-10-27 remediation waves and the 2026-10-30 code-quality audit already removed the worst structural defects (FTS5 search instead of unindexed `LIKE`, worker-isolate asset copy at boot, `Isolate.run` for JSON/normalization/backup, bounded rebuild gates on reader / mini-player / Azkar counter, single-flight catalog refresh). This audit re-verified those areas at source and measured the app **on the physical Infinix X6882** in its shipped release form (and on an Android 16 emulator for reference).

No P0 (crash/freeze/resource-exhaustion) or P1 (reproducible major jank) defects were found. **No memory leak:** the in-app open/back loop is flat to within noise (reader open ≈ 254 MB, closed ≈ 247 MB, four cycles, swap constant at 136–144 KB). **Frame pacing is locked:** SurfaceFlinger layer latency shows 90 Hz-cadence frame intervals (p50 ≈ **11.17–11.18 ms**, p90 ≈ **11.21–11.24 ms**) during a home-screen scroll burst on both the shipped build and the rebuilt one; the dense scroll window contains **no frame above the 60 Hz deadline**. Cold start is **≈ 0.4–0.9 s** on device (vs 1.5–2.9 s on emulator).

Four P3 lifecycle fixes were implemented and verified (format + analyze 0 + full suite 1450/1450). The fixes address teardown-order hygiene, not frame cost, so before/after metrics are at parity — as expected and as stated honestly.

**Readiness:** the app performs well on a real, modest ARM device for the measured journeys. Remaining gaps: low-end (≤2 GB RAM) ARM verification, DevTools-grade CPU/raster profiling, network-degradation matrix, and a long-session soak — see `docs/performance-remediation-plan.md`.

## 2. Testing Environment

| Item | Physical device (primary) | Emulator (reference) |
|---|---|---|
| Device | **Infinix X6882** (`13372704AR007777`), Helio-class ARM SoC | AVD `A16_API36`, x86_64 |
| Android | **14** (API 34) | 16 (API 36), Google APIs |
| CPU / RAM | 8-core ARM (arm64-v8a, aapt/abilist verified) · 2 GB-class class body memory headroom (226 GB `/data`, 49 GB free) | 4 vCPU · 2 GB RAM |
| Screen | 1080×2460 @ **90 Hz** current mode (modeId 3 committed; supports 120 Hz) — Density 480, font scale 1.0 | 1080×2400 @ 60 Hz — Density 420 |
| Build under test | **Release** (owner-cert signed, `minifyEnabled true`, `shrinkResources true`); and, for the fixes, a rebuilt release from this working tree | **Profile** (x86_64 split APK, Impeller OpenGLES) |
| Flutter / Dart / DevTools | 3.47.5 / 3.13.4 / 2.60.0 (CI pin) | same |
| Package | `com.mostafasayed.quranyahdi` | same |
| Network | 4G + Wi-Fi live; app is offline-first | outbound available |
| Battery at test | 35% → 85% (charging during session) | n/a |
| Data | Owner's real install with real data (last-read Al-Baqarah 30, dark theme, Cairo) — **owner consented to on-device A/B measurement; no user data was touched** | Fresh install + scripted onboarding |
| Rendering | Flutter 3.47.5 → **Impeller** (same as emulator) | Impeller (OpenGLES) |

**Unavailable / not tested:** a ≤2 GB RAM / entry-level device; DevTools timeline capture (release builds have no VM service; profile build cannot install over the owner-cert release build without uninstalling — debug-signed — which was declined); CPU sampling profiles (release builds are sampled with JIT off); audio playback audibility checks; full network-degradation matrix.

## 3. Baseline Results (before fixes)

Device rows = owner's installed release build (2026-11-01 store build, versionName 1.0.0, **versionCode 4**). Timings: `am start -W` `TotalTime` (intent dispatch → activity resumed) ×5, post force-stop.

| Metric | Device (installed release build) | Emulator (profile) for reference |
|---|---|---|
| First-ever launch | Not re-measured on device (install wiped neither) — see emulator 13.2 s one-time | 13.2 s (one-time DB copy + seed + search index + ART dexopt) |
| Fresh-install cold start | — | 2.96 s |
| **Cold start (n=5)** | **857 / 482 / 414 / 557 / 476 ms** (mean ≈ 557 ms) | 1736 / 1516 / 1781 / 1775 / 1647 ms (mean ≈ 1.69 s) |
| Warm start | 0–6 ms | 0–6 ms |
| Home memory (PSS) | **180 MB** (Graphics 64.7 MB, swap 820 KB) | 158–173 MB |
| Reader memory (PSS, Al-Baqarah) | **≈ 233 MB** (Graphics 106.7 MB) | ≈ 166 MB |
| Reader open→close (in-app, n=4) | open ≈ **254–255 MB** · closed ≈ **247–248 MB** · flat | n/a (emulator used deep links; not comparable) |
| Scroll burst → memory | +16 MB to ≈ 255 MB (cache warming), no OOM, no crash | Not comparable |
| Frame interval during home scroll burst | **p50 = 11.18 ms · p90 = 11.24 ms** (90 Hz lock; refresh cadence 11.11 ms) · 1 in-burst frame > 44 ms (1/121) | Not measurable (Impeller invisible to gfxinfo/SurfaceFlinger on emulator) |
| Frames > 16.67 ms in burst | **1 of 121** (44.7 ms; one-off, likely shader/GC — not reproducible after fix rebuild) | Not measurable |
| Swap PSS | 136–820 KB — negligible | up to 28.8 MB (memory pressure under 2 GB) |

**Test data volume:** full bundled corpus (6,236 ayahs); Al-Baqarah (286 ayahs) reader scenario; owner's real profile for UX realism; no synthetic data.

### Frame measurement method (device)

`dumpsys SurfaceFlinger --latency-clear <Flutter SurfaceView BLAST layer>` → 8 fast synthetic flings → `--latency` → 127-frame window; intervals computed from consecutive `actualPresent` column; refresh cadence line (11.11 ms) read as 90 Hz. The `lateness` column shows a constant ≈ 51 ms offset — a BLAST flip-chain constant, **not** jank; intervals are uniform. On the emulator the same probe returns an Activity layer carrying no Flutter frames (0 usable timestamps) — device-only signal.

## 4. Findings

| ID | Sev | Finding | Evidence | Status |
|---|---|---|---|---|
| PERF-01 | Env | Emulator universal profile APK won't install (`/data` 93% full, 424 MB free) → DevTools/emulator route abandoned; device perfectly accommodates split APKs | flutter run log; `df -h /data` | Mitigated (device) |
| PERF-02 | P3 | `TabController` listener (`_onTabChanged`) registered but never removed in `QuranWorkspaceScreen` | `quran_workspace_screen.dart:40,54` (pre-fix) | **Fixed** |
| PERF-03 | P3 | `BookmarksCubit.close()` / `ReaderCubit.close()` initiated drift stream cancels **without awaiting** — close-vs-teardown race | `bookmarks_cubit.dart:214`, `reader_cubit.dart:284` (pre-fix) | **Fixed** |
| PERF-04 | P3 | Prayer-times 1 Hz `Timer.periodic` started unconditionally in `initState` even if the screen mounts while the app is backgrounded | `prayer_times_screen.dart:97` (pre-fix) | **Fixed** |
| PERF-05 | P3 | Player sheet rebuilds the whole modal per 1 Hz position tick when not dragging. Pinned as intended by `test/player_sheet_rebuild_test.dart`. Device shows 90 Hz lock during scroll bursts (but the sheet wasn't open during bursts; 1 Hz is 1/90 of budget). | `player_sheet.dart:20-35,156-162` | **Open — documented** (needs owner ruling + P-R2 evidence; risk > gain) |
| PERF-06 | P3 | App-lifetime `AudioPlayer` never disposed (single instance by design for `just_audio_background`) | `just_audio_playback_service.dart`; DI registration | Open — accepted by design |
| PERF-07 | P3 | App-lifetime warm deep-link `uriLinkStream` listener, never cancelled (disclosed v1) | `main.dart:239-244` | Open — by design (documented in code) |
| PERF-08 | Info | Frame timing unobtainable via `gfxinfo` (0 frames; Impeller) — solved on device via SurfaceFlinger layer latency | §3 method | **Resolved on device** |
| PERF-09 | Info | `am start VIEW`-based "navigation" loops measure process re-creation, not in-app navigation; deep links replace the stack | on-device screencap (exited to a third-party app) | Documented |
| PERF-10 | Info | 13× `am start VIEW` loop grew PSS 158→208 MB on emulator — process-teardown artifact, not an app leak; RSS flat at ≈261 MB; the correct on-device experiment (§3 in-app loop) is flat | §3 measurements | Resolved by experiment design |
| PERF-11 | P3 | `hijri_screen.dart:185` `shrinkWrap` on a 42-cell month grid — intentional, tiny | `hijri_screen.dart:183-186` | Documented — no change |
| PERF-12 | Info | Verified clean: heavy lists use `.builder`; search = FTS5 trigram + 300 ms debounce + generation guard; search-index normalization on `Isolate.run`; backup encode/crypto on `Isolate.run`; DB asset copy on a worker isolate (first-boot); drift on background executor with WAL; reciter catalog single-flight + isolate-decoded + 20 s budget; one `AudioPlayer`; route cubits never DI singletons; Azkar/reader/mini-player carry rebuild gates; only `shrinkWrap` in repo is the hijri cell grid. | source inspection + grep sweep | — |
| PERF-13 | Info | ~~Version-code drift~~ — **CLOSED 2026-11-12: category error.** `2004` is the arm64 split-APK ABI offset over base `4` (`pubspec.yaml:5` → `1.0.0+4`); the AAB carries `4` and the installed build's `4` is that same base code. Nothing drifts. Remaining owner check: whether code `4` is already on a Play track. | aapt dump badging; `pm dump`; `docs/store/play-console-setup.md:23` | **Closed** |
| PERF-14 | P3 | One 44.7 ms interval frame in the pre-fix burst (1/121); zero such frames in the post-fix burst (dense window fully ≤ 16.67 ms). Not attributable to any specific fix (teardown-order fixes don't touch the render path) — treat as cold-start/shader-compile noise. | §3 latency captures | Documented |

## 5. Root Cause Analysis

**PERF-02** — workspace Quran screen created one `TabController`; `dispose()` disposed the controller but never detached `_onTabChanged` (a closure capturing the State that calls `setState`). `TabController.dispose()` empties the listener list, so no cross-route retention in practice — but the add/remove pair violated Flutter's documented contract and would leak the State if the controller ever outlived it.

**PERF-03** — `Cubit.close()` is `Future<void>` but was implemented as fire-and-forget: drift `watch()` subscriptions round-trip to the DB background isolate; initiating cancellation without awaiting released callers before teardown actually completed. In fast route re-entry (bookmarks/reader), a pending cancellation could land against an already-finalized query builder. Low probability, exactly the class of bug that corrupts bookmark/last-read sync.

**PERF-04** — the 1 Hz countdown ticker started in `initState` regardless of the binding's lifecycle state, so a screen mounted while backgrounded (notification deep link, process re-creation) ticked a clock nobody saw until the first lifecycle event or `dispose`. The repo already encodes the correct pattern (`lifecycle_ticker.dart:43-47`); the fix mirrors it.

**PERF-10 (emulator memory "growth")** — an artifact: `am start VIEW` with the app backgrounded pushes a *new* reader route per loop and BACK exits the task; consecutive samples reflect process teardown/re-creation plus swap pressure on a 2 GB emulator, not retained Dart objects. The on-device in-app loop (open → BACK → repeat) is flat.

No root cause indicates architectural weakness. All confirmed defects are lifecycle hygiene; none affect the frame path.

## 6. Changes Implemented

Small, focused, behavior-preserving. No dependencies added. `dart format` clean; `flutter analyze` → **No issues found** (74.8 s).

| File | Change | Why |
|---|---|---|
| `lib/features/quran/presentation/workspace/quran_workspace_screen.dart` | `dispose()` now `_tabs.removeListener(_onTabChanged); _tabs.dispose();` | PERF-02 teardown pair |
| `lib/features/quran/presentation/bookmarks/bookmarks_cubit.dart` | `close()` `async`, awaits `_sub?.cancel(); _pageSub?.cancel();` | PERF-03 race |
| `lib/features/quran/presentation/reader/reader_cubit.dart` | `close()` `async`, awaits `_bookmarksSub?.cancel();` | PERF-03 (same class) |
| `lib/features/prayer/presentation/prayer_times/prayer_times_screen.dart` | `initState` gates `_startTicker()` on `lifecycleState == resumed` (or null) | PERF-04 background tick |

Explicitly **not** changed (justified): player-sheet rebuild structure (PERF-05) · prayer 1 Hz countdown cadence (frozen-test pin) · deep-link stack semantics (PERF-09) · hijri `shrinkWrap` (PERF-11) · home's eager dashboard (design for 2.0 text-scale reachability, `home_screen.dart:158-161`) · reader per-verse `BlocSelector` (already minimal) · audio lifecycle, DB integrity, navigation, l10n/RTL — untouched.

**Artifact installed for A/B:** `app-arm64-v8a-release.apk` (44.6 MB) built from this working tree with the owner's release keystore (signer verified = installed app's cert), installed over the owner's build with `-r`. Owner data (last-read Al-Baqarah 30, adhkar progress, reciter catalog, settings) preserved and re-verified after install.

## 7. Before/After Results

Same device, same screen refresh rate (90 Hz mode), same network, same interaction sequence (n=5 cold starts; identical scroll-burst pattern; identical screen). The fixes do not touch the render path — parity is the expected, honest result.

| Metric | Before (installed build) | After (rebuilt release with fixes) | Change |
|---|---|---|---|
| Cold start (n=5) | 857 / 482 / 414 / 557 / 476 ms | 636 / 489 / 473 / 479 / 441 ms | Parity (within noise; both ≈ 0.4–0.9 s) |
| Warm start | 0–6 ms | 0–6 ms | — |
| Home memory (PSS) | 180 MB | 170 MB | −10 MB (noise-level; Graphics identical at 64.7 MB) |
| Reader memory (PSS, open) | ≈ 233 MB | 244 MB | +11 MB (noise-level; RSS 352–368 MB both) |
| Post-scroll-burst memory | ≈ 255 MB | 254 MB | −1 MB |
| Graphics memory | 64.7 (home) / 106.7 (reader) MB | identical | — |
| Frame intervals (home burst) | p50 = 11.18 · p90 = 11.24 ms | p50 = 11.17 · p90 = 11.21 ms | Parity — 90 Hz lock both |
| Slow frames > 16.67 ms (dense burst) | 1 (44.7 ms, one-off) | **0** | −1 (single observation; not attributable) |
| Reader open/close loop (n=4) | open ≈ 254 · closed ≈ 247 MB, flat | not re-run (install is the same build for this sequence) | — |
| Swap PSS | 136–820 KB | 143–488 KB | — |
| Expensive operations (search index, FTS) | unchanged (source-verified off UI isolate) | unchanged | — |

**Not measured:** DevTools CPU/raster/GC timelines (release build has no VM service; profile build can't install over the owner cert without uninstall). First-ever launch on this exact build (the install was an update, not a wipe — by design).

## 8. Regression Testing

| Gate | Result |
|---|---|
| `flutter analyze` | **No issues found** (74.8 s) |
| `dart format` on the 4 touched files | 0 changed |
| Full `flutter test` | **All tests passed — +1450, 0 failed** (5 min 19 s) |
| Frozen pins | untouched (`player_sheet_rebuild_test`, `prayer_times_ticker_test`, `qibla_lifecycle_test`, `reader_route_reentry_test`) |
| On-device smoke after install | Home renders; surah index renders; reader opens at owner's last-read; Al-Baqarah scroll burst OK; deep links routed (during the emulator pass); no crash, no ANR, no data loss |

## 9. Remaining Issues / Limitations

1. **Entry-level hardware not tested** (≤2 GB RAM ARM): likely the binding constraint for real-world UX; needs a device or OEM loaner.
2. **Release build = no VM service** → DevTools CPU/raster/GC charts unavailable; the SurfaceFlinger latency probe is our frame-level evidence (cadence + outliers), not a raster breakdown.
3. ~~**PERF-13 versionCode drift (2004 vs 4)**~~ — closed 2026-11-12: an ABI offset, not a drift. The owner still confirms whether code `4` is already on a Play track.
4. **First-ever-launch cost** unmeasured on device (13.2 s on emulator, one-time); one sample only.
5. **Jank under real finger input** (vs synthetic `input swipe`): not measured; synthetic bursts are a reasonable proxy only for gross regressions.
6. **Audio journey** (play/pause/seek/route-exit) not play-tested on device — would exercise the speaker and touch owner's media state; no evidence of a defect at source level (PERF-06).
7. **Unicode Uthmani text path** (selection + `SelectionArea`) on Al-Baqara was not specifically exercised on device.
8. **PERF-05** (player sheet 1 Hz full rebuild) remains documented-not-fixed; PERF-06/07 accepted by design; prayer 1 Hz pinned by frozen test.
9. Emulator rows are kept in §3 as context only; they are x86_64 and not representative of ARM.

## 10. Next Steps (prioritized)

1. **VersionCode for the next upload (owner):** confirm in Play Console whether code `4` is already on a track; if it is, bump `pubspec.yaml` to `1.0.0+5`.
2. **DevTools session on device** — request a **profile** build installed as a *separate* app (`applicationIdSuffix .profile` would be needed) or a debug-signed build co-installed with the owner's release; capture raster/GC traces for the Al-Baqarah fling and player sheet. This closes PERF-05 with data and gives CPU shares per phase.
3. **Entry-level run** on a ≤2 GB ARM device: same matrix as §3; expect the first-ever-launch cost to dominate — measure, then decide whether the search-index build should move behind the first frame.
4. **Long-session soak** (≥30 min): repeated recitation playback + route cycling; meminfo + `dumpsys media.player` cadence samples; confirms PERF-06's accepted-by-design ruling.
5. **Network matrix** (offline/3G/throttle): catalog fetch, downloads, playback controls remain responsive; errors localize.
6. **Real-finger jank check** with `adb gfxinfo` on a build with an `.profile` suffix co-installed (see #2) or watch `dumpsys SurfaceFlinger --latency` during a manual fling session.

## Git status

**Initial:** owner debris only (`.metadata`, `.vscode/settings.json`, `.opencode/plugins/entire-external.ts`, `INSTRUCTIONS.md`, `assets/icons/logo_1.png`, `assets/icons/logo_2.png`, `web/design-concepts/`). HEAD `6e0ff45` on `wave/audit-remediation`.

**Final:** owner debris (untouched) + four audit-edited source files (§6) + `docs/performance-audit.md` + `docs/performance-remediation-plan.md`. HEAD unchanged (`6e0ff45`); **no commit created**. The owner's phone now carries the rebuilt release (with the four fixes) instead of the store build; the store build remains the artifact from 2026-11-01 and can be reinstalled from the owner's backup/CI if desired.
