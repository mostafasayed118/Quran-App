# Privacy Policy — Quran Yahdi

Last updated: 2026-10-16 · Applies to version 1.0.0

> **Honest TL;DR:** This app is **fully offline at its core**. **We collect no data about you. At all.** No accounts, no sign-in, no analytics, no ads, no tracking, and no server of ours ever receives anything from your device.

## What the app does NOT do

- Does not collect any personal data (name, email, phone, location history, photos…).
- Does not create accounts or require sign-in.
- Contains no analytics/usage-tracking SDKs.
- Shows no ads.
- Does not send any data from your device to any server of ours — we do not operate any user-data server at all.

## Permissions the app requests, and why

| Permission | Why it is needed | Where it is used |
|---|---|---|
| Location (fine/coarse) | To compute the **nearest city to you** automatically, for accurate prayer times and Qibla direction | Processed **on-device only**; your position is compared against a city list bundled inside the app to pick the nearest one. **The location is never sent, stored, or shared with any party — ever.** |
| Internet | To download/stream **Quranic audio recitations** from the free mp3quran.net service, and to download text packs for tafsir and hadith | Connections are limited to pinned, hardcoded CDN endpoints only. No device identifiers or personal data are attached to these requests. |
| Notifications / exact alarms | To remind you of prayer times **that you enable yourself** in settings | Reminders are computed and scheduled locally on your device. |
| Foreground service (audio) | To keep recitation playing when the app is minimized | Playback info (reciter & surah names) appears in the media bar and stays on your device. |

> You can deny the location permission and still use the app: pick your city manually from the city picker screen.

## Data stored on your device

Everything the app stores stays **on your device only**, inside the app's private storage:

- Your settings (dark mode, font size, selected city, reminder time).
- Your bookmarks and last-read position.
- The audio files and text packs you downloaded.
- Your worship-tracker and tasbih logs.

Uninstalling the app permanently deletes all of it. We keep no copy.

## Content and open-source attributions

- **Quran text (Hafs):** the Uthmani and Imlaei text (114 surahs, 6,236 ayahs) is bundled inside the app's local database — fully offline.
- **Adhkar, duas, and ruqyah:** compilations gathered from classical public collections, bundled offline.
- **Recitations:** streamed/downloaded from the free mp3quran.net service; recitation rights belong to the reciters and their owners.
- **Fonts:** the Cairo font is licensed under the SIL Open Font License (its text file is bundled inside the app); the HafsSmart and me_quran mushaf typefaces are used under free-redistribution terms from Quran typography publishers — license documentation is to be completed before final store submission.

## Questions

For any question about this policy, contact the app owner through the project's GitHub repository.
