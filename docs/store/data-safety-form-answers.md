# Play Console — Data Safety Form Answers (v1.0.0)

> Derived verbatim from the privacy sources — `PRIVACY.md` (AR) / `PRIVACY.en.md` (EN) — plus a live
> permission census of the codebase. Evidence-or-silence rule: every answer below cites its
> source fact. Anything not citable would be flagged `OPEN-FOR-OWNER` — there are none.

Last updated: 2026-10-19 · App: Quran Yahdi (`com.mostafasayed.quranyahdi`) · v1.0.0+3

## 1. Permission census (run live against the code)

Release manifest `android/app/src/main/AndroidManifest.xml`:

| Permission | Location | Why it exists |
|---|---|---|
| `INTERNET` | `AndroidManifest.xml:3` | Audio recitation streaming/download (mp3quran CDN) + text-pack downloads (pinned jsDelivr endpoints). `lib/features/recitation/data/reciter_repository.dart` (`recitersApiEndpoint` — `https://mp3quran.net/api/v3/reciters?language=ar`), `assets/data/library_catalog.json` (jsDelivr URLs). Cited in `PRIVACY.md` line 20 (AR) / `PRIVACY.en.md` line 20 (EN). |
| `ACCESS_COARSE_LOCATION` | `AndroidManifest.xml:7` | Nearest-city detection for prayer times & Qibla — **processed on-device only, never transmitted** (`lib/features/prayer/data/location_service.dart:27-36`; bundled 156-city list `assets/data/cities.json`; `PRIVACY.md` line 19 (AR) / `PRIVACY.en.md` line 19 (EN)). |
| `ACCESS_FINE_LOCATION` | `AndroidManifest.xml:8` | Same flow as coarse (higher accuracy for the same on-device computation). |
| `SCHEDULE_EXACT_ALARM` | `AndroidManifest.xml:9` | User-enabled prayer/azkar reminders, computed and scheduled locally (`PRIVACY.md` line 21 (AR) / `PRIVACY.en.md` line 21 (EN)). |

Also present on the release manifest but **not user-data related**: `WAKE_LOCK` (:4),
`FOREGROUND_SERVICE` (:5), `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (:6) — background audio
playback plumbing for the recitation player (media notification with reciter/surah name,
stays on-device; `PRIVACY.md` line 22 (AR) / `PRIVACY.en.md` line 22 (EN)).

`POST_NOTIFICATIONS` is **not declared in any of our manifests**: it comes from the
resolved plugin's own manifest, merged at build time —
`flutter_local_notifications-22.3.2` pub cache,
`android/src/main/AndroidManifest.xml:4`
(`<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`),
with the runtime grace flow in `lib/features/notifications/data/notifications_binding.dart`
(`requestBootPermission` — the first-boot POST_NOTIFICATIONS grace helper).

Debug/profile manifests also declare `INTERNET` (`android/app/src/debug/AndroidManifest.xml:6`,
`android/app/src/profile/AndroidManifest.xml:6`) — development tooling only, absent from
the release artifact.

## 2. The form, answered line-by-line

### Q: "Does your app collect or share any of the required user data types?"

**Answer: NO.**

Play's definition of "collect" is **data transmitted off the user's device**. The app is
offline-first: it operates no user-data server, includes no analytics SDKs, no ads, and
no tracking (`PRIVACY.md` lines 5–13 (AR) / `PRIVACY.en.md` lines 5–13 (EN)). The only network traffic is
**user-initiated content downloads** (audio recitations, tafsir/translation/hadith text
packs) from pinned, hardcoded CDN endpoints — no device identifiers or personal data are
attached (`PRIVACY.md` line 20 (AR) / `PRIVACY.en.md` line 20 (EN)).

### Q: "Is this data shared with third parties?"

**Answer: Not shared.** There is nothing transmitted that could be shared; no
third-party SDKs exist in the dependency set (`pubspec.yaml` — UI/storage/audio/notify
packages only, no analytics/ads).

### The honest per-data-type matrix (prepared for the form's data-type pages)

| Data type | Accessed at runtime | Transmitted off device | Stored remotely | Shared |
|---|---|---|---|---|
| Precise / coarse location (FINE + COARSE) | Yes — when-in-use, only for nearest-city conversion | **No** — position is compared in memory against the bundled 156-city list | **No** | **No** |
| Personal info / IDs / contacts / media / photos | No | — | — | — |
| App activity, diagnostics, browsing | No analytics/telemetry exists | — | — | — |
| Downloaded content (audio, text packs) | User-initiated downloads to app-private storage | No (requests carry no user data) | No | No |

Because nothing is transmitted, per Play's rules **none of these count as "collected"** —
which is why the top-level answer above is NO.

### Q: Deletion

**Answer: Nothing is stored remotely.** All app data lives in app-private storage on the
device (settings, bookmarks, last-read, downloads, worship logs) and **uninstalling the
app permanently deletes all of it; no copy exists anywhere else** (`PRIVACY.md`
line 36 (AR) / `PRIVACY.en.md` line 36 (EN)). In-app deletion of downloads/packs is also available.

### Q: Account deletion URL

**N/A — the app has no accounts and no sign-in** (`PRIVACY.md` line 10 (AR) / `PRIVACY.en.md` line 10 (EN)).

### Q: "Is data encrypted in transit?"

**N/A — nothing is transmitted** (the form skips this when the top-level answer is NO).

> The CDNs that serve user-initiated content still see the request: streaming and downloaded
> recitations come from `mp3quran.net` and text-pack installs from `cdn.jsdelivr.net`, so each
> service necessarily sees the user's IP as ordinary service-provider processing. No device
> identifier, account, or personal data is attached to those requests, so the answers above
> stay **NO**.

## 3. Cross-check against `PRIVACY.md` (AR) / `PRIVACY.en.md` (EN)

| Privacy-source claim | Form answer | Verdict |
|---|---|---|
| "لا نجمع أي بيانات عنك، إطلاقًا" / "We collect no data about you. At all." (l.5 AR / `PRIVACY.en.md` l.5 EN) | "Does your app collect or share…?" → NO | MATCH |
| Location on-device only, never sent/stored/shared (l.19 AR / `PRIVACY.en.md` l.19 EN) | Location matrix: accessed, never transmitted | MATCH |
| Connections limited to pinned CDN endpoints, no identifiers (l.20 AR / `PRIVACY.en.md` l.20 EN) | Network = content downloads only | MATCH |
| Reminders computed & scheduled locally (l.21 AR / `PRIVACY.en.md` l.21 EN) | `SCHEDULE_EXACT_ALARM` justification | MATCH |
| "Uninstalling the app permanently deletes all of it. We keep no copy." (l.36 AR / `PRIVACY.en.md` l.36 EN) | Deletion answer | MATCH |
| Foreground audio playback info stays on device (l.22 AR / `PRIVACY.en.md` l.22 EN) | WAKE_LOCK / FOREGROUND_SERVICE census note | MATCH |

**Result: no mismatch found — the privacy sources required no data-safety edits.**

## 4. OPEN-FOR-OWNER

None. Every answer above is citable to `PRIVACY.md` / `PRIVACY.en.md` or to a file/line in the codebase.
If the owner later adds any backend, analytics, or ads, this document must be re-answered
from scratch.
