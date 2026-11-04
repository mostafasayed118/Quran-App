# Adhan Selection — Design Spec

**Date:** 2026-11-04
**Repo:** `quran_yahdi` @ `d709209` (`main`)
**Status:** **APPROVED** by owner, 2026-11-04. No product code written yet; implementation plan pending.
**Mode:** architectural (new subsystem across settings, notifications, assets, backup, audio).

---

## 1. Goal

Let the user choose which adhan they hear, from nine bundled recitations, with a default and a way to change it later.

Two delivery surfaces, both required:

1. **A short clip** (~25 s) as the prayer notification's sound.
2. **The full adhan** (2–3.5 min) played on demand, with a stop control.

The user picks a global adhan and may override Fajr only.

---

## 2. Recorded decisions

| # | Decision | Rationale | Cost if wrong |
|---|---|---|---|
| D1 | Ship **all 9**, re-encoded to **64 kbit/s mono AAC** | 25.5 MB of 128 k stereo would quadruple the app's asset payload (currently ~6.5 MB). 64k mono lands at ≈14.7 MB with acceptable voice quality on a phone speaker. | Re-upload an asset set; no code change (catalog is data). |
| D2 | **Global selection + Fajr override** | Matches the ask; covers the common "softer/longer adhan at dawn" need without a per-prayer picker. | Data model already extends to a per-prayer map without migration. |
| D3 | Default reciter = **`abdulbasit_abdulsamad`** | Egyptian default calculation method already in the app; culturally the expected default for the audience. | One-field change. |
| D4 | Unattributed track is labelled **«أذان تخشع له القلوب»**, id `khushu` | The source file carries no reciter; the title is the only honest label. | One-field change. |
| D5 | **One Android channel per adhan**, id `quran_yahdi_adhan_<id>` | Android freezes a channel's sound at creation, so a shared channel would leave existing users stuck on the first sound forever. Selecting an adhan *is* selecting a channel — the bug becomes structurally impossible. | Cosmetic clutter in Android notification settings, bounded at 10 channels. |
| D6 | Full playback reuses **`just_audio_background`** | Already a dependency; `AudioServiceActivity` is already registered in `MainActivity`. Gives a media notification with a stop button that works from the lock screen — no new audio machinery. | Replace one player implementation behind a port. |
| D7 | Catalog is **data**, not code (`const List<AdhanTrack>`) | Adding or removing a reciter becomes a two-file drop + one entry, no logic change. Critical because the shipping set depends on rights clearance. | None. |

### Open rating: licensing

All nine are commercial recordings. `docs/store/licensing-matrix.md` carries 7 `OPEN-FOR-OWNER` rows and REL-03 is `still open`. **This spec makes the shipping set a data change so the legal position can be adjusted without code.** Submission is blocked on rights clearance, not on this work.

---

## 3. Catalog

`lib/core/domain/adhan_catalog.dart` — immutable value type + the list. Reciter names live in data as `nameAr`/`nameEn`, matching the existing `city` precedent (`selected_city` stores `nameAr`/`nameEn`), not in ARB.

| id | nameAr | nameEn | Duration |
|---|---|---|---|
| `abdulbasit_abdulsamad` | عبد الباسط عبد الصمد | Abdul Basit Abdulsamad | 223.6 s |
| `ali_ahmed_mulla` | علي أحمد ملا (الحرم المكي) | Ali Ahmed Mulla (Makkah) | 205.1 s |
| `omar_hisham` | عمر هشام العربي | Omar Hisham Al Arabi | 180.0 s |
| `mohamed_qassas` | محمد مروان قصاص | Mohamed Marwan Qassas | 226.6 s |
| `khushu` | أذان تخشع له القلوب | A Heart-Softening Adhan | 210.8 s |
| `mohamed_tarek` | محمد طارق | Mohamed Tarek | 171.5 s |
| `islam_sobhy` | إسلام صبحي | Islam Sobhy | 171.8 s |
| `nasser_alqatami_1` | ناصر القطامي (١) | Nasser Al-Qatami (1) | 127.5 s |
| `nasser_alqatami_2` | ناصر القطامي (٢) | Nasser Al-Qatami (2) | 135.2 s |

List order **is** display order (default first, then the rest).

```dart
class AdhanTrack {
  const AdhanTrack({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.durationSeconds,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final int durationSeconds;

  String get assetPath => 'assets/audio/adhan/$id.m4a';
  String get clipPath => 'assets/audio/adhan/clips/${id}_clip.m4a';
  /// Android raw-resource name for the notification clip (lowercase + underscore).
  String get clipResource => '${id}_clip';
}

const String kDefaultAdhanId = 'abdulbasit_abdulsamad';
const List<AdhanTrack> kAdhanCatalog = <AdhanTrack>[ ... ];

AdhanTrack adhanById(String? id); // unknown/null -> the default track
```

`adhanById` never returns null: an id written by a newer build, a hand-edited backup, or a removed track all resolve to the default. This is the forward-compatibility seam.

---

## 4. Assets

```
assets/audio/adhan/<id>.m4a            64 kbit/s mono AAC, 44.1 kHz
assets/audio/adhan/clips/<id>_clip.m4a  first 25 s, 64 kbit/s mono, 2 s fade-out
```

- Both directories must be declared in `pubspec.yaml` separately — Flutter asset directory entries are **not** recursive.
- The 128 k original masters move **out of `assets/`** into `_adhan_masters/` and never ship. Keeping 25.5 MB of masters in `assets/` would put them in the APK *and* in git.
- **Verified hazard:** the nine masters are currently **untracked and not gitignored** (no matching rule exists today), sitting directly in `assets/`. A `git add -A` would commit 25.5 MB, and a build would bundle it. `.gitignore` gains `_adhan_masters/` as part of W1, and the masters are moved before any staging.
- `tools/build_adhan_audio.ps1` regenerates both sets from the masters with ffmpeg, deterministically:

```
ffmpeg -i <master> -ac 1 -ar 44100 -c:a aac -b:a 64k -movflags +faststart <id>.m4a
ffmpeg -i <master> -t 25 -af "afade=t=out:st=23:d=2" -ac 1 -ar 44100 -c:a aac -b:a 64k -movflags +faststart <id>_clip.m4a
```

- `-movflags +faststart` keeps the MP4 index at the front so playback starts without a full read.
- `res/raw/` (Android) is created and populated by copying the 9 clips at build-prep time, because `RawResourceAndroidNotificationSound` reads an Android raw resource, not a Flutter asset. `tools/build_adhan_audio.ps1` writes both destinations so they cannot drift.
- `android/app/src/main/res/raw/` file names must be lowercase `[a-z0-9_]` — the catalog ids satisfy this.

---

## 5. Preferences

Two plain string keys in the existing settings table. No JSON envelope.

| Key | Type | Default | Meaning |
|---|---|---|---|
| `adhan_id` | String | `abdulbasit_abdulsamad` | Global adhan |
| `adhan_fajr_id` | String, **nullable** | `null` | Fajr override; null = "same as global" |

Resolution rule, used by both surfaces:

```
trackFor(prayer) = adhanById(prayer == fajr ? (adhan_fajr_id ?? adhan_id) : adhan_id)
```

Both keys are added to `lib/features/backup/data/backup_inventory.dart` as literals and to `test/backup_inventory_pin_test.dart`. That pin is **Class B (inventory)** and the change is additive, which the frozen-test policy explicitly allows — the report must state the exact set delta.

On import, an unknown `adhan_id` is not an error: it resolves to the default. Never reject a whole backup for one unknown enum value.

---

## 6. Domain ports

Settings presentation and the notification scheduler both need adhan behaviour, and neither may import another feature's `data/` (`allowedFeatureEdges` in `test/architecture_guard_test.dart` is the exact set). So both go through `lib/core/domain/`:

```dart
// lib/core/domain/adhan_preferences.dart
abstract interface class AdhanPreferences {
  Future<String> adhanId();
  Future<String?> fajrAdhanId();
  Future<void> setAdhanId(String id);
  Future<void> setFajrAdhanId(String? id); // null = same as global
}

// lib/core/domain/adhan_player.dart
abstract interface class AdhanPlayer {
  /// Plays the full adhan for [trackId]; stops any recitation first.
  Future<void> play(String trackId);
  /// Plays a short preview for the picker (no media session takeover).
  Future<void> preview(String trackId);
  Future<void> stop();
  Stream<AdhanPlaybackState> get state;
}
```

Implementations: `lib/features/notifications/data/adhan_preferences_impl.dart` and `lib/features/notifications/data/just_audio_adhan_player.dart`, both registered in `lib/app/di/injector.dart`. Both live in the `notifications` feature so that `settings/` depends only on the core ports and no new feature→feature edge appears.

**Recitation conflict rule:** `AdhanPlayer.play` calls the recitation playback port's `stop()` before starting. Explicit, tested, not incidental.

---

## 7. Settings UI

`settings_screen.dart` gains one row: **"صوت الأذان"**, subtitle = current reciter's `nameAr`, trailing chevron → `AdhanPickerScreen`.

`AdhanPickerScreen` (`lib/features/settings/presentation/adhan_picker_screen.dart`):

- AppBar title from l10n.
- Section 1: **الأذان الافتراضي** — 9 rows, radio selection, a leading preview/stop toggle button per row.
- Section 2: **أذان الفجر** — a "مثل الافتراضي" row (selected when `adhan_fajr_id == null`) followed by the same 9 rows.
- A dedicated **`AdhanPickerCubit`** owns the picker — **not** `SettingsCubit`. `SettingsCubit` is shared across the settings route, and AGENTS.md forbids registering a route-scoped cubit as a shared singleton; reusing it would leak picker state between visits. The router creates `AdhanPickerCubit` through `RouteCubitScope` like every other route cubit, and it depends only on the `AdhanPreferences` and `AdhanPlayer` ports.
- Each mutation is serialized through a future chain (the same `_serialized` idiom as `settings_cubit.dart:49-61`), so rapid taps cannot interleave writes.
- After a successful write the cubit asks the reminder-scheduler port to reschedule, so the next notification posts on the correct channel.
- `SettingsCubit` only *reads* `adhan_id` to render the row subtitle; it never writes it.
- Preview playback stops on selection change, on row re-tap, and on screen dispose.

`SettingsState.ready` gains `adhanId` and `adhanFajrId` via `@Default`, so no existing construction site breaks.

---

## 8. Notifications

- Channel id: `quran_yahdi_adhan_<resolvedId>`; `AndroidNotificationDetails(<channelId>, …)` keeps the current `importance.high` / `priority.high`.
- Sound: `sound: RawResourceAndroidNotificationSound(track.clipResource)`.
- The channel is created implicitly by `flutter_local_notifications` on first post — no explicit `createNotificationChannel`, so switching adhans costs one channel and never mutates an existing one.
- **Fajr** uses the Fajr override; every other prayer uses the global.
- Switching adhan does **not** need to cancel already-scheduled notifications: the sound is a property of the channel used at *post* time. Existing code already reschedules on settings change; we keep that.
- Bounded cost: at most 10 channels ever exist. Documented in code with a comment explaining why one channel per track is deliberate, so nobody "simplifies" it back into the lock bug.

---

## 9. Full playback

- Entry point: a notification **action button** on the prayer notification, "تشغيل الأذان" → `onDidReceiveNotificationResponse` with an action id carrying the track id.
- `AdhanPlayer.play(trackId)` → stops recitation → `just_audio` `setAsset(assetPath)` → play.
- Because `just_audio_background` is initialised app-wide, the OS media notification provides **pause/stop** from the lock screen.
- On completion, the player releases and the media notification clears.
- Failure (plugin not ready at boot, missing asset) must fail open with a `dev.log` entry and a localized snackbar if a UI is present — never a raw exception (AGENTS.md).
- No autoplay at prayer time in this wave. Playback is always user-initiated, which sidesteps Doze/foreground-service policy entirely.

---

## 10. l10n, backup, architecture

- **l10n:** additive AR + EN pairs only, never change an existing value: `adhanTitle`, `adhanDefaultSection`, `adhanFajrSection`, `adhanSameAsDefault`, `adhanPreview`, `adhanStopPreview`, `adhanPlayAction`. Regenerate and commit generated files.
- **Backup:** +2 keys as above; pin test updated (Class B, additive, disclosed).
- **Architecture:** no new feature→feature edge. Adhan ports live in `lib/core/domain/`; both consumers depend on the ports. `test/architecture_guard_test.dart` must stay green untouched.
- **Boot rule:** the adhan player initialises behind `runApp` with the existing 1.5 s fail-open cap; a play request arriving before readiness is queued, never dropped.

---

## 11. Testing (write the test first)

| Test | Asserts |
|---|---|
| `adhan_catalog_test` | ids unique and lowercase-safe; every `assetPath` **and** `clipPath` exists on disk; every track has non-empty `nameAr`/`nameEn`; `adhanById(null)` and `adhanById('nope')` return the default |
| `adhan_preferences_test` | round-trip of `adhan_id`; `adhan_fajr_id` null vs set; unknown stored id resolves to default |
| `adhan_resolution_test` | the `trackFor(prayer)` matrix: global only; Fajr override set; override null falls back; unknown override falls back |
| `adhan_channel_test` | channel id is `quran_yahdi_adhan_<id>`; Fajr resolves the override; every catalog id produces a **distinct** channel id (this is the regression guard for the channel-lock bug) |
| `backup_inventory_pin_test` | +2 keys, literals equal the owner constants |
| `backup_roundtrip_adhan_test` | export contains both keys; import restores them; import of an unknown id does not fail the restore |
| `adhan_picker_test` | 9 rows render; current selection is checked; "same as default" row reflects null; tapping preview calls the player once; disposing stops preview |
| `adhan_player_test` | `play` stops recitation first; a missing/unready plugin logs and fails open |

Fakes are hand-rolled (no `mocktail`/`bloc_test` — not in the repo).

---

## 12. Out of scope

- Autoplay of the adhan at prayer time from a background wake (Doze, exact alarms, foreground-service policy — a separate, much larger wave).
- Per-prayer (all five) selection.
- User-imported adhan files via `file_picker`.
- Silent/"no adhan" pseudo-entry — `prayer_reminder_enabled` already covers disabling.
- iOS notification sound (`≤30 s`, `.caf`/`.aiff`/`.wav`) — the Android path only in this wave; the catalog's `clipPath` makes the iOS wiring a later adapter.
- Rights clearance for the nine recordings (owner track, REL-03).

---

## 13. Suggested execution shape

Three gated waves, each landing green on `flutter analyze` + `flutter test`:

1. **W1 — assets + catalog + preferences + ports.** Move the 9 masters to `_adhan_masters/`, add it to `.gitignore`, run the ffmpeg pipeline (full files + clips + `res/raw/`), `AdhanTrack`/catalog, `AdhanPreferences`, tests 1–3, backup keys + pin.
2. **W2 — settings UI + preview.** `AdhanPickerScreen`, cubit fields, l10n, tests 7.
3. **W3 — notifications + playback.** Per-adhan channels, Fajr resolution, notification action, `AdhanPlayer` on `just_audio_background`, tests 4, 8, and the resolution matrix.

W1 is independently shippable: the picker in W2 works before W3 wires the sound.
