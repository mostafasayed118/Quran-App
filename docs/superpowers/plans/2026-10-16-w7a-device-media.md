# Quran Yahdi — Wave 7a (Device & Media Polish) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The device-layer polish wave: background recitation playback with a media notification, a real "current location" path for prayer times, a live compass for the qibla dial, and the wave's own verification tool (true device smoke — the e340f7a lesson institutionalized). Three platform plugins enter through the EXISTING seams (PlaybackService facade, CityRepository city selection, QiblaService bearing) — zero architecture changes.

**Tech Stack:** THREE new packages this wave (the largest admission yet, all Flutter Favorites-class plugins): `just_audio_background` (background audio + media notification — wraps just_audio under the hood so ONLY the existing `JustAudioPlaybackService` file changes), `geolocator` (location, when-in-use), `sensors_plus` (magnetometer/accelerometer heading). Each: `flutter pub add`, disclose version + transitives, VM-purity NOT required (they are platform plugins) — HEADLESS tests therefore NEVER construct them: services are injectable fakes. PM fallback order if admissions fail: just_audio_background → full `audio_service` wrapper (escalate BEFORE building); geolocator → `location` package; sensors_plus → hand-written MethodChannel (escalate, do not improvise).

**Companion waves:** W7b (notifications + RTL/visual sweep + i18n) and W7c (release: keystore outside repo, .aab, privacy page, store listing, minima decision) follow; owner-dependent items are parked there.

**Baseline:** main after the UX-W1 close (`b84776b`). Gates: analyze 0, suite 155/155, porcelain empty.

## Global Constraints

- Binding rules (all waves): analyze 0; TDD red→green for pure logic (nearest-city math, heading mapping); explicit-pathspec commits with these exact messages; **commit messages are NEVER translated — byte-copy them**; NO push; ticks at close-out; one writer on `main`; start gate verbatim.
- **DEVICE SMOKE IS NOW A FIRST-CLASS GATE** (the W6-hotfix lesson): after each platform commit AND at close-out, run the committed tool `tools/device_smoke.ps1` (Task 1 builds it) with the physical Infinix X6882 attached (`adb devices` lists `13372704AR007777`). A wave is NOT green without: install Success + launch + process alive 10s + zero `FATAL EXCEPTION` in fresh logcat. Executor records the tool's summary each run.
- **headless test law**: `geolocator`, `sensors_plus`, `just_audio_background` plumbing is NEVER exercised by unit tests; pure decision logic is extracted into injectable pure helpers (nearest-city selector, heading mapper, background-init flag guard) and tested with plain `test()`. Widget tests stay faked as always (pumpHost + fakes; no platform channels).
- Playback facade owns the background change: `just_audio_playback_service.dart` is the ONLY Flutter-audio file touched; `playback_service.dart` contract unchanged; PlaybackCubit untouched. If `just_audio_background` forces a contract change → STOP (PM ruling; fallback = full audio_service wrapper behind the same facade).
- l10n additive + symmetric; Arabic-Indic numerals at call sites; teardown-safe standing rules; router/frozen tests untouched (sixth+ waves held).
- Permissions: geolocator needs `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION` (when-in-use only; NO background location) — manifest additive lines inside the location commit; iOS plist entries are OUT (iOS deferred, owner item).

---

### Task 1: Start gate + device smoke tool

**Files:**
- Create: `tools/device_smoke.ps1` (ASCII-only output! PS 5.1 quirks: no `&&`, no UTF8 corruption — the script prints English-only)

**Tool contract (implement FIRST — it gates everything):**
```powershell
# tools/device_smoke.ps1 — param: -ApkPath (default build\app\outputs\flutter-apk\app-debug.apk)
# 1) locate adb (%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe or ANDROID_SDK_ROOT env) else FAIL 2
# 2) adb install -r <apk> -> must print Success (else FAIL 3)
# 3) adb shell am start -n com.mostafasayed.quranyahdi/.MainActivity
# 4) poll pidof up to 10s (2s interval) -> alive required (else FAIL 4)
# 5) adb logcat -d scan for "FATAL EXCEPTION" (fresh buffer: -c before start) -> none required (else FAIL 5)
# 6) print DEVICE-SMOKE: PASS and exit 0; any failure prints DEVICE-SMOKE: FAIL <n> and exits nonzero
```
- [ ] **Step 1:** start gate verbatim (`git rev-parse --short=7 HEAD; git status --porcelain; git branch --show-current; flutter --version`) — expected HEAD `b84776b` or later intervening `docs/superpowers/` only; record it. Baseline `flutter test` once → record B (expect 155; MEASURE).
- [ ] **Step 2:** implement the tool; run it against the CURRENT W6-built debug APK (rebuild first if stale: `flutter build apk --debug`) → expect PASS on the Infinix. This also re-proves the workspace on-device before any change.
- [ ] **Step 3: Gates + commit**

```powershell
git add tools/device_smoke.ps1
git commit -m "feat(w7a): device smoke tool (install, launch, alive, fatal-scan)"
```

---

### Task 2: Background playback + media notification

**Files:**
- Modify: `pubspec.yaml`/`pubspec.lock` (just_audio_background)
- Modify: `lib/features/recitation/playback/just_audio_playback_service.dart` ONLY (impl swap), `lib/main.dart` (one init call before runApp: `JustAudioBackground.init(incognito: false, ...)` per package API — READ the package README/source in the pub cache FIRST and quote its exact init + player-API differences in the report BEFORE usage)
- Modify: ARB?? no — MediaItem metadata comes from PlaybackCubit state (reciter name + surah number are already in state); service builds the MediaItem tag per load (title = `قرآن يَهدي — <reciter>`, artist = reciter name, id = url/file path string per API contract)
- Create: `test/background_init_guard_test.dart` (pure guard only — see below)

**Design ruling (PM):** with `just_audio_background`, setAudioSource grows a required tag. The facade keeps its contract by threading an internal `_lastMediaItem` built from the cubit-provided metadata — playback_service.dart source stays pure; the CUBIT passes title fields through `loadAndPlay(source, mediaTitle: String, artist: String)` defaulting to empty. Contract change → EXACTLY one optional named param added to the interface + facade + both call sites (cubit passes from its state). If the real API needs more → STOP.
- [ ] **Step 1 (red):** pure guard test — `BackgroundInitGuard.requiredInitCalled(bool)` style helper (file `lib/features/recitation/playback/background_init_guard.dart`, pure) that the app uses in `main.dart`: if `JustAudioBackground.init` throws/missed, run must STILL complete per package contract — quote the package's actual failure mode from cache source and test OUR wrapper decision against it (document the chosen semantics).
- [ ] **Step 2:** admission + impl swap + init wiring; gates; then **DEVICE PROOF**: `tools/device_smoke.ps1` PASS, plus `adb shell dumpsys media_session | findstr quranyahdi` prints an active session while a surah plays, plus minimization keeps audio (record the two commands' outputs).
- [ ] **Step 3: Gates + commit**

```powershell
flutter analyze
flutter test
tools/device_smoke.ps1
git add pubspec.yaml pubspec.lock lib/features/recitation/playback lib/main.dart test/background_init_guard_test.dart
git commit -m "feat(w7a): background playback via just_audio_background (facade-internal swap)"
```

---

### Task 3: Current location → nearest city

**Files:**
- Modify: pubspec (geolocator), manifest (+2 location permissions, when-in-use only)
- Create: `lib/features/prayer/data/location_service.dart` (thin injectable wrapper: `Future<CityCoordinates?> currentPosition()` returning null on denial/disabled — NEVER throw upward) + nearest-city pure helper IN `city_repository.dart` (`City nearestTo(double lat, double lng)` — haversine over the loaded catalog; pure Dart, real golden tests ALLOWED: fixed coords → mathematically fixed nearest among fixture cities)
- Modify: `city_picker_screen.dart` (+ ONE "استخدم موقعي/Use my location" action at the list top — existing picker screen, existing l10n pattern, new keys), `arbs`, injector (LocationService registration)
- Create: `test/city_nearest_test.dart`, `test/location_service_test.dart` (fake channel absent — service tested via injected `Future<CityCoordinates?> Function()` resolver override pattern)

**Rulings:** location failure (denied/offline/timeout) → neutral hint `locationUnavailable` + manual picker as-is; NO settings permissions page; nearest = **haversine over the 156 bundled cities** (no reverse geocoding, zero paid APIs); selection writes the SAME `selected_city` settings key (nameAr/nameEn from the matched city).
- [ ] **Step 1 (red):** nearest-city goldens (fixture catalog of 5 cities on a plausible map — assert the mathematically nearest for 2 query points; equator/dateline-free); resolver-override service tests: granted→coords, denied→null.
- [ ] **Step 2 (green):** implement + manifest permissions + picker action (loading spinner during fetch; on success selects + pops with the existing selection flow).
- [ ] **Step 3: l10n:** `useMyLocation` استخدم موقعي/Use my location · `locating` جارٍ تحديد الموقع…/Locating… · `locationUnavailable` تعذّر تحديد الموقع — اختر يدويًا/Could not get location — pick manually.
- [ ] **Step 4: Gates + COMMIT + DEVICE PROOF**

```powershell
flutter gen-l10n
flutter analyze
flutter test
tools/device_smoke.ps1
git add pubspec.yaml pubspec.lock lib/features/prayer/data android/app/src/main/AndroidManifest.xml lib/features/prayer/presentation/city_picker lib/core/di/injector.dart lib/l10n test/city_nearest_test.dart test/location_service_test.dart
git commit -m "feat(w7a): current-location flow (nearest bundled city, manual fallback)"
```

DEVICE PROOF extra (record outputs): grant location IN-UI (device dialog), tap the action with GPS on → picker selects the nearest city; then deny → hint appears.

---

### Task 4: Live compass on the qibla dial

**Files:**
- Modify: pubspec (sensors_plus)
- Create: `lib/features/qibla/data/heading_service.dart` (Stream<double> headingDeg|null — wraps device sensors stream, null when sensors unavailable/denied (some devices lack magnetometer))
- Modify: `lib/features/qibla/presentation/qibla_screen.dart` + `qibla_cubit.dart` (heading stream merged into state: dial arrow animates toward `bearing − heading`; static mode unchanged when heading null while a tiny hint remains? PM ruling: NO new dials — same dial; when live heading flows, the dial rotates with the device; cancellation on dispose (teardown-safe standing rule); throttle/curve: map raw degrees through the existing AnimatedRotation-like approach — one `AnimatedRotation` param, duration 150-200ms, no animation package)
- Modify: ARBs +regenerated (`compassLive` المقياس حي/Dial follows your device, one-line hint under the dial; visible ONLY when heading is live)
- Create: `test/heading_service_test.dart` (pure mapping test via injected `Stream<double> Function()`), extend `test/qibla_screen_test.dart` with a FAKE heading stream test (rotated angle assertion via AnimatedRotation's angle param)

**Rulings:** sensors stream is subscribed ONLY on the main dart isolate via the service; no `streamSub` leaks (cancel in cubit close); screen keeps working headless (static) when the channel throws.
- [ ] **Step 1 (red):** heading mapping (0/90/180/270 → dialed arrow transform values via the cubit state's `heading` field math) + service injection null-path.
- [ ] **Step 2 (green):** implement + screen wiring + hint key.
- [ ] **Step 3: Gates + COMMIT + DEVICE PROOF**

```powershell
flutter gen-l10n
flutter analyze
flutter test
tools/device_smoke.ps1
git add pubspec.yaml pubspec.lock lib/features/qibla lib/l10n test/heading_service_test.dart test/qibla_screen_test.dart
git commit -m "feat(w7a): live compass dial (sensors heading, static fallback)"
```

DEVICE PROOF extra (record): with the qibla screen open, `adb shell dumpsys sensorservice | findstr -i "qibla OR magnetic"` not required — record `logcat` free of sensor channel errors during 15s of physical rotation; visual confirmation sentence in the report (owner visible).

---

### Task 5: Close-out

- [ ] **Step 1: Full gates ONCE** — build_runner · gen-l10n · analyze (0) · FULL suite (B 155 → ≈165-170; MEASURE per-file) · pub outdated (3 admissions disclosed) · apk debug exit 0 ballpark · apk release exit 0 + bytes (byte-exact expectation NOTE: plugins change native code several times mid-wave; release determinism is expected only FROM the settled close-out tree — record ×2 to prove it) · porcelain empty · unpushed · **tools/device_smoke.ps1 final PASS**.
- [ ] **Step 2: Tick this plan** (targeted lines only; the header PROSE holds a literal `- [ ]`; .NET UTF8-no-BOM; numstat + non-checkbox filter recorded):

```powershell
git add docs/superpowers/plans/2026-10-16-w7a-device-media.md
git commit -m "docs(w7a): mark plan checkboxes complete"
```

- [ ] **Step 3:** Final report §1-§10 (start-gate verbatim · baseline B · commit table · THREE package-intake quotes (versions+transitives+exact API surfaces read from cache) · gates table incl. EVERY device-smoke summary + the three DEVICE PROOF command outputs · itemized disclosures · STOPs · incidents · unpushed · state · NO PUSH).

## Explicit non-goals (this wave)

- Notifications/scheduling (prayer reminders, azkar) — W7b.
- RTL boilerplate removal, EmptyState no-city migration prayer_times/qibla — W7b visual sweep.
- Release engineering: keystore/signing, .aab, privacy page, store listing, gradle/AGP/Kotlin minima — W7c (owner decisions pending).
- Magnetic declination correction (logged W7c note — Egypt offset single-digit degrees), battery-optimized sensor throttling, iOS anything (owner item).

## Self-Review (PM, pre-dispatch)

- Three platform plugins behind three EXISTING pure seams (facade, city selection, bearing) — the architecture WAS built for this wave; UI stays cubic + stateless.
- The device smoke tool converts the W6-hotfix lesson into an executed gate; every platform change now carries on-device proof.
- Headless test law prevents platform channels from ever entering `flutter test`; pure helpers (haversine nearest, heading mapping, init guard) take the test weight.
- Fallback orders + STOP bars defined for all three admissions; no improvised MethodChannels.
- Frozen surface unchanged; l10n small and symmetric; Arabic-Indic at call sites.
