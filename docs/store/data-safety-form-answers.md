# Play Console — Data Safety Form Answers (v1.0.0)

> Derived verbatim from the privacy sources — `PRIVACY.md` (AR) / `PRIVACY.en.md` (EN) — plus a live
> permission census of the codebase. Evidence-or-silence rule: every answer below cites its
> source fact. Anything not citable would be flagged `OPEN-FOR-OWNER` — there are none.

Last updated: 2026-10-30 · App: Quran Yahdi (`com.mostafasayed.quranyahdi`) · v1.0.0+3

## 1. Permission census (run live against the code)

Release manifest `android/app/src/main/AndroidManifest.xml`:

| Permission | Location | Why it exists |
|---|---|---|
| `INTERNET` | `AndroidManifest.xml:3` | Audio recitation streaming/download (mp3quran CDN) + text-pack downloads (pinned jsDelivr endpoints) + a reciter-catalog fetch at startup when the local list is empty (normally the first run). `lib/features/recitation/data/reciter_repository.dart` (`recitersApiEndpoint` — `https://mp3quran.net/api/v3/reciters?language=ar`; `ensureCatalog()` :220-225), warm-up invoked from `lib/main.dart:87,97-99`; `assets/data/library_catalog.json` (jsDelivr URLs). Cited in `PRIVACY.md` line 23 (AR) / `PRIVACY.en.md` line 23 (EN). |
| `ACCESS_COARSE_LOCATION` | `AndroidManifest.xml:7` | Nearest-city detection for prayer times & Qibla — **processed on-device only, never transmitted** (`lib/features/prayer/data/location_service.dart:27-36`; bundled 156-city list `assets/data/cities.json`; `PRIVACY.md` line 22 (AR) / `PRIVACY.en.md` line 22 (EN)). Coarse only: the manifest does not request `ACCESS_FINE_LOCATION`. |
| `SCHEDULE_EXACT_ALARM` | `AndroidManifest.xml:8` | User-enabled prayer/azkar reminders, computed and scheduled locally (`PRIVACY.md` line 24 (AR) / `PRIVACY.en.md` line 24 (EN)). |

Also present on the release manifest but **not user-data related**: `WAKE_LOCK` (:4),
`FOREGROUND_SERVICE` (:5), `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (:6) — background audio
playback plumbing for the recitation player (media notification with reciter/surah name,
stays on-device; `PRIVACY.md` line 25 (AR) / `PRIVACY.en.md` line 25 (EN)).

`POST_NOTIFICATIONS` is **not declared in any of our manifests**: it comes from the
resolved plugin's own manifest, merged at build time —
`flutter_local_notifications-22.3.2` pub cache,
`android/src/main/AndroidManifest.xml:4`
(`<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`),
with the runtime grace flow in `lib/features/notifications/data/notifications_binding.dart`
(`requestBootPermission` — the first-boot POST_NOTIFICATIONS grace helper).

Plugin manifests also merge `android.permission.VIBRATE` and
`android.permission.ACCESS_NETWORK_STATE` into the built artifact. Neither touches user data:
vibration backs local reminder notifications, and network-state is connectivity plumbing.
Verified with `aapt dump permissions` on the signed release APK (2026-10-30); the artifact
declares **no `ACCESS_FINE_LOCATION`** and **no `com.google.android.gms.permission.AD_ID`**.

Debug/profile manifests also declare `INTERNET` (`android/app/src/debug/AndroidManifest.xml:6`,
`android/app/src/profile/AndroidManifest.xml:6`) — development tooling only, absent from
the release artifact.

## 2. The form, answered line-by-line

### Q: "Does your app collect or share any of the required user data types?"

**Answer: NO.**

Play's definition of "collect" is **data transmitted off the user's device**. The app is
offline-first: it operates no user-data server, includes no analytics SDKs, no ads, and
no tracking (`PRIVACY.md` lines 5–13 (AR) / `PRIVACY.en.md` lines 5–13 (EN)). Network
traffic is limited to content from pinned, hardcoded CDN endpoints — no device identifiers
or personal data are attached (`PRIVACY.md` line 23 (AR) / `PRIVACY.en.md` line 23 (EN)):

- **User-initiated** audio recitations and tafsir/translation/hadith text packs.
- **One automatic request at startup** when the reciter list is empty (normally only the first
  run): the mp3quran reciter catalog is fetched so playback works before the user opens the
  recitations screen (`lib/features/recitation/data/reciter_repository.dart:220-225`, called
  from `lib/main.dart:87,97-99`). It carries no parameters, identifiers, or user data.

### Q: "Is this data shared with third parties?"

**Answer: Not shared.** No user data is transmitted, so there is nothing that could be shared;
no third-party analytics, advertising, or attribution SDK exists in the dependency set
(`pubspec.yaml` — UI/storage/audio/notify packages only).

### The honest per-data-type matrix (prepared for the form's data-type pages)

| Data type | Accessed at runtime | Transmitted off device | Stored remotely | Shared |
|---|---|---|---|---|
| Coarse location (only — FINE is not requested) | Yes — when-in-use, only for nearest-city conversion | **No** — position is compared in memory against the bundled 156-city list | **No** | **No** |
| Personal info / IDs / contacts / media / photos | No | — | — | — |
| App activity, diagnostics, browsing | No app-owned analytics/telemetry exists (see platform note below) | — | — | — |
| Reciter catalog (app content, not user data) | Fetched automatically at startup when the local list is empty | Request carries **no** device identifier or personal data | No | No |
| Downloaded content (audio, text packs) | User-initiated downloads to app-private storage | No (requests carry no user data) | No | No |

Because no user data is transmitted, per Play's rules **none of these count as "collected"** —
which is why the top-level answer above is NO.

> **Platform note (do not confuse with app telemetry):** when the app is installed from
> Google Play, Play itself may collect aggregated crash/ANR diagnostics under Google's own
> terms. The app contains no crash-reporting SDK and uploads nothing; see
> `docs/operations-runbook.md` §1 and the note in `PRIVACY.md` / `PRIVACY.en.md`.

### Q: Deletion

**Answer: Nothing is stored remotely.** All app data lives in app-private storage on the
device (settings, bookmarks, last-read, downloads, worship logs) and **uninstalling the
app permanently deletes all of it; no copy exists anywhere else** (`PRIVACY.md`
line 39 (AR) / `PRIVACY.en.md` line 39 (EN)). In-app deletion of downloads/packs is also available.

### Q: Account deletion URL

**N/A — the app has no accounts and no sign-in** (`PRIVACY.md` line 10 (AR) / `PRIVACY.en.md` line 10 (EN)).

### Q: "Is data encrypted in transit?"

**N/A on the form — the top-level answer is NO, so Play skips this section.** For accuracy:
all network calls are HTTPS, and the release manifest sets `usesCleartextTraffic="false"`
(`AndroidManifest.xml:17`).

> The CDNs still see the request: streaming, downloaded recitations, and the startup catalog
> fetch (normally only the first run) come from `mp3quran.net`; text-pack installs come from `cdn.jsdelivr.net`. Each
> service necessarily sees the user's IP as ordinary service-provider processing, and
> `mp3quran.net` also sees the request path `/api/v3/reciters`. No device identifier, account,
> or personal data is attached to those requests, so the answers above stay **NO**.

## 3. Cross-check against `PRIVACY.md` (AR) / `PRIVACY.en.md` (EN)

| Privacy-source claim | Form answer | Verdict |
|---|---|---|
| "لا نجمع أي بيانات عنك، إطلاقًا" / "We collect no data about you. At all." (l.5 AR / `PRIVACY.en.md` l.5 EN) | "Does your app collect or share…?" → NO | MATCH |
| Location (coarse only) on-device only, never sent/stored/shared (l.22 AR / `PRIVACY.en.md` l.22 EN) | Location matrix: accessed, never transmitted | MATCH |
| Connections limited to pinned CDN endpoints, no identifiers (l.23 AR / `PRIVACY.en.md` l.23 EN) | Network = content downloads + startup catalog fetch | MATCH |
| Startup reciter catalog fetch is automatic and carries no identifiers (l.23 AR / `PRIVACY.en.md` l.23 EN) | Network answer lists the automatic startup request | MATCH |
| Reminders computed & scheduled locally (l.24 AR / `PRIVACY.en.md` l.24 EN) | `SCHEDULE_EXACT_ALARM` justification | MATCH |
| "Uninstalling the app permanently deletes all of it. We keep no copy." (l.39 AR / `PRIVACY.en.md` l.39 EN) | Deletion answer | MATCH |
| Foreground audio playback info stays on device (l.25 AR / `PRIVACY.en.md` l.25 EN) | WAKE_LOCK / FOREGROUND_SERVICE census note | MATCH |

**Result: no mismatch remains.** The 2026-10-30 pass corrected two stale claims in this
document — it had listed `ACCESS_FINE_LOCATION` (removed from the manifest) and described
all network traffic as user-initiated (the startup catalog warm-up is automatic).
`PRIVACY.md` / `PRIVACY.en.md` were corrected in the same pass.

## 4. OPEN-FOR-OWNER

None. Every answer above is citable to `PRIVACY.md` / `PRIVACY.en.md` or to a file/line in the codebase.
If the owner later adds any backend, analytics, or ads, this document must be re-answered
from scratch.
