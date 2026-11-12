# Performance Remediation Plan — Quran Yahdi

Companion to `docs/performance-audit.md` (2026-11-09, rev 2 — physical-device pass). Scope: work that genuinely remains after the device audit, in priority order. Nothing here is implemented; each item names the measurement that would justify it. None of this authorizes pushing or releasing without the owner's explicit go.

## P-R1 · versionCode decision (owner, immediate) — CORRECTED 2026-11-12

- **Why:** the base versionCode is `4` (`pubspec.yaml:5` → `1.0.0+4`); `2004` is the arm64 split-APK ABI offset, not a drift (PERF-13 was a category error).
- **Done-when:** owner confirms in Play Console whether code `4` is already on a track; if so, bump `pubspec.yaml` to `1.0.0+5` before the next upload.

## P-R2 · DevTools-capable side build on device

- **Why:** release builds expose no VM service, so raster/GC/CPU timelines are still unmeasured; PERF-05 (player-sheet 1 Hz full rebuild) and the one 44.7 ms outlier both need real timeline evidence instead of inference.
- **Done-when:** a `.profile`-suffixed (or debug-signed) build co-installed beside the owner's release; one Al-Baqarah fling trace + one player-sheet-open trace captured; decision rule for PERF-05 made explicit (extract position-scoped seek/time row only if its raster cost is visible).
- **Risk:** the new build variant is additive (no source change); keep the owner's release untouched.

## P-R3 · Entry-level (≤2 GB RAM ARM) run

- **Why:** the device measured (Infinix X6882) is mid-range; first-ever launch cost and GC behavior on a Go-edition device are the likeliest real-world failure modes we have not seen.
- **Done-when:** same matrix as audit §3 on the slowest available device; first-ever-launch time included (the 13.2 s emulator sample flags this as the one number that might be user-visible).

## P-R4 · Long-session audio soak (≥30 min)

- **Why:** PERF-06 (app-lifetime `AudioPlayer`, dead dispose path) is accepted by design on paper only — one early `am`-prompted log showed geolocator/audio pipes behaving, never a 30-minute sample set.
- **Done-when:** sustained playback + route cycling; meminfo cadence shows no growth; `dumpsys media.player` tracks the single player; no ANR; if growth appears, escalate to an owner decision.

## P-R5 · Network degradation matrix

- **Why:** Phase 7 of the audit skill was not exercised; offline-first paths (catalog fail-open, 15 s connect / 2 min receive timeouts, RTL errors) are source-verified only.
- **Done-when:** 3G/offline/airplane: catalog failure → localized retry; downloads fail gracefully; reader and playback controls stay interactive; no ANR under `dumpsys activity lru` + logcat watch.

## P-R6 · Cold-start one-time cost on slow hardware (conditional)

- Only if P-R3 shows first-ever launch above ~5 s of visible splash: consider moving the search-index build behind the first frame (it is already off the render path and fail-open — verify before changing). Requires a TDD loop and a frozen-test-aware plan; do not improvise.

## P-R7 · Real-finger jank pass

- Synthetic `input swipe` bursts are a gross regression proxy only. With P-R2's profile build: fling the reader and watch `dumpsys SurfaceFlinger --latency` (method in audit §3) during a manual session; note any in-burst interval above 16.67 ms and its frequency. If >1% of dense-window frames exceed it, treat as P1 and escalate.

## Deferred / out of scope

- Prayer 1 Hz → minute cadence: frozen-test pin (`prayer_times_ticker_test.dart`); needs an owner ruling first.
- Universal APK size (66.5 MB → arm64-only ≈25.4 MB ≈ 44.6 MB already achieved via per-ABI splits): release-track work, not runtime performance.
- hijri `shrinkWrap`, home eager dashboard, deep-link stack semantics, app-lifetime listeners, PERF-05/6/7: accepted as documented.

*Each item needs the owner's go; none were executed. The audit and this plan are the only artifacts added by the 2026-11-09 session.*
