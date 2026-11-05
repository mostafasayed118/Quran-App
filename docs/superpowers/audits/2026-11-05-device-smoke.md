# Device smoke — notifications, qibla, WorkManager — 2026-11-05

> **Mode:** read-only verification on the physical device. No tracked file was
> edited during the run. The one fix below (`android/app/src/main/res/raw/keep.xml`)
> was added afterwards and is committed as `e3a879d`; this evidence doc lands
> with the docs close-out.

## Device / build

| | |
|---|---|
| Device | Infinix X6882 (`X6882-OP`) |
| Android | 14 (SDK 34) |
| Serial | `13372704AR007777` |
| Package | `com.mostafasayed.quranyahdi` |
| Installed before | versionCode 3 · 2026-11-01 19:53 |
| Installed for this run | versionCode 4 · `1.0.0` · release APK signed with the owner cert |
| Source tip | `main` @ `6d0cda4` + the `keep.xml` fix, now committed as `e3a879d` |
| APK under test | `app-release.apk` 44,684,626 B (after `keep.xml`; 42,839,417 B before it) |
| Rebuild | `PUBLISH_RELEASE=true flutter build apk --release --target-platform android-arm64` |

## Verified on device

| Check | Result | Evidence |
|---|---|---|
| Install over the +3 build | **PASS** | `adb install -r` → `Success`; `versionCode=4` |
| Cold launch | **PASS** | MainActivity focused; `pidof` 13177; no `FATAL EXCEPTION` in logcat |
| Onboarding city picker (regression from the previous wave) | **PASS** | City picker opened inside `/onboarding`, Cairo selected, returned to the flow: `المدينة: القاهرة / تغيير المدينة` |
| POST_NOTIFICATIONS | **PASS** | `granted=true` |
| Exact alarms | **PASS** | `SCHEDULE_EXACT_ALARM: allow` |
| Rolling plan armed | **PASS** | 55 exact `RTC_WAKEUP` alarms for the package over the 7-day horizon, `exactAllowReason=permission`; first: wird `2026-11-05 20:00`, Fajr `2026-11-06 04:44`, Dhuhr `11:40`, Asr `14:42`, Maghrib `17:04`, Isha `18:24` |
| Reliability card — battery | **PASS (feature works)** | Initially showed «تحسين استهلاك البطارية قد يوقف التذكيرات — استثنِ التطبيق.» with «إصلاح». The action opened the system Battery Optimization screen; after `cmd deviceidle whitelist +com.mostafasayed.quranyahdi`, returning to Settings cleared the section. |
| Reliability card — schedule failure | **PASS (feature works)** | On the pre-`keep.xml` release build, changing the azkar time produced «تعذّر جدولة التذكيرات — افتح التطبيق مرة أخرى ليُعيد المحاولة.» — the new row surfaced a real failure (see Finding 1). |
| Live azkar notification | **PASS** | Azkar time set to `19:05`; at `19:06` the shade showed «أذكار الصباح» (channel `quran_yahdi_reminders`, id 2, importance 4). |
| Notification tap routing | **PASS** | Tapping the notification opened the **الأذكار** screen (payload `azkar`). |
| Qibla live compass | **PASS** | `المقياس حي`; `١٣٦° عن الشمال`; turn hint changed `٦١°` → `٦٠°` between samples; dial painted with the Arabic cardinals (شمال/شرق/جنوب/غرب) and the correct direction. |
| WorkManager periodic job | **PASS** | `JOB androidx.work.systemjobscheduler:u0a393/…` registered with `Minimum latency: +14m59s…`; job `#0` ran and WorkManager scheduled `#1` with `Delay=+13m34s…`; app listed `exempted` / `WHITELISTED` after the battery fix. The release `dev.log` is not visible in logcat, so the job's own stamp was not readable; the scheduler cycle is the evidence. |

## Findings

1. **Release blocker (fixed locally, uncommitted): `shrinkResources` strips the adhan raw resources.**
   The clips live in `android/app/src/main/res/raw/*_clip.m4a` and are referenced only from Dart
   (`RawResourceAndroidNotificationSound('<id>_clip')`), so the release resource shrinker removes
   every `res/raw` entry. The debug APK contains all 9 clips; the pre-fix release APK contains none.
   Scheduling a prayer reminder with a selected adhan throws, cancels the previously armed plan,
   and leaves the device with no prayer alarms. The new `scheduleFailed` row made this visible.
   **Fix:** `android/app/src/main/res/raw/keep.xml` with `tools:keep="@raw/*_clip"`.
   After rebuilding the release APK, `aapt2` lists all 9 `raw/…_clip` resources, the boot schedule
   produced 55 exact alarms including the prayer horizon, and the live azkar notification fired.
   **Fixed in `e3a879d`; the store AAB is rebuilt at that tip before upload.**
2. **Low / UX — battery fix opens the generic list.** «إصلاح» opens the Battery Optimization list,
   not a per-app dialog, so the user has to find Quran Yahdi in a long list. The safe alternative
   (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` with the package) needs the
   `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission and a Play policy review; left as-is for v1.
3. **Low / diagnostics — release logs are invisible.** `dart:developer` logs do not reach logcat in
   the release build, so the schedule failure could only be observed through the UI card. The card
   is sufficient for users; a durable failure stamp (like the WorkManager stamp) would help the
   device check. Not implemented.

## Open items

- The `keep.xml` fix is committed as `e3a879d`; the store `+4` AAB is rebuilt at that tip (see
  `docs/store/play-console-setup.md` for the final size/SHA).
- Re-run this smoke against the rebuilt AAB/APK after the fix lands (the APK used here already had it).
- Owner-gated: Play App Signing SHA-256 into `web/public/.well-known/assetlinks.json` after the first
  upload, licensing written terms, and the final signed-device smoke on the store artifact.

## Evidence files

`C:\Users\ASUS\AppData\Local\Temp\opencode\device_smoke_2026-11-05\`:
`smoke_01_home.png` · `smoke_03_after_city.png` · `smoke_05_home_ready.png` ·
`smoke_06_qibla.png` · `smoke_08_settings.png` · `smoke_09_battery.png` ·
`smoke_22_settings_after_keep.png` · `smoke_24_notification.png` ·
`smoke_25_notification_tap.png` · `ui_*.xml` · `workmanager_logcat.txt` ·
`schedule_failure_logcat.txt`.
