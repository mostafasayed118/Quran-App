# Privacy Policy — Quran Yahdi

Last updated: 2026-10-24 · Applies to version 1.0.0

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
| Internet | To download/stream **Quranic audio recitations** from the free mp3quran.net service, and to download text packs for tafsir and hadith | Connections are limited to two fixed, pinned endpoints hardcoded in the app: `mp3quran.net` (audio) and `cdn.jsdelivr.net` (tafsir and translation packs, pinned to a specific commit). No device identifiers or personal data are attached to these requests. |
| Notifications / exact alarms | To remind you of prayer times **that you enable yourself** in settings | Reminders are computed and scheduled locally on your device. |
| Foreground service (audio) | To keep recitation playing when the app is minimized | Playback info (reciter & surah names) appears in the media bar and stays on your device. |

> You can deny the location permission and still use the app: pick your city manually from the city picker screen.

## Data stored on your device

Everything the app stores stays **on your device only**, inside the app's private storage:

- Your settings (selected city, reminder times).
- Your bookmarks and last-read position.
- The audio files and text packs you downloaded.
- Your worship-tracker and tasbih logs.
- You can manually export your data to a file from Settings; the file goes only to the destination you choose — nothing is sent to any server in the process. That backup file is an unencrypted JSON file, so store and share it with care.

Uninstalling the app permanently deletes all of it. We keep no copy.

## The website (quranyahdi.pages.dev)

The Quran Yahdi website creates no accounts, requires no sign-in, and uses no cookies of ours, no analytics, no ads, and no tracking. Your preferences are stored in your browser's local storage (localStorage) on your device only, under these keys:

- `qy:theme` — light/dark mode.
- `qy:reader` — reader settings (font size, view, selected reciter, layout).
- `qy:bookmarks` — bookmarks.
- `qy:last-read` — last-read position.
- `qy:player:row` and `qy:player:surah` — player state (the last reciter and surah played).

Clearing site data in your browser permanently removes these keys.

On the Qibla page (/qibla), the browser asks for location permission when you choose to use your location; the Qibla bearing is computed in the browser on your device, and your position is never sent to us or stored.

The site is served by Cloudflare Pages, which processes standard request metadata (such as IP address) to deliver and protect the site under Cloudflare's own privacy policy.

External requests are limited to the same two fixed endpoints the app uses: `mp3quran.net` (audio and the reciter API) and `cdn.jsdelivr.net` (tafsir and translation packs); no device identifiers or personal data are attached to these requests.

For any question about this policy, email us at [mustafasayed20002@gmail.com](mailto:mustafasayed20002@gmail.com).

## Content and open-source attributions

- **Quran text (Hafs):** the Uthmani and Imlaei text (114 surahs, 6,236 ayahs) is bundled inside the app's local database — fully offline.
- **Adhkar, duas, and ruqyah:** compilations gathered from classical public collections, bundled offline.
- **Recitations:** streamed/downloaded from the free mp3quran.net service; recitation rights belong to the reciters and their owners.
- **Hadith:** Sahih al-Bukhari (Arabic) is the classical public-domain text; the bundled digital edition's provenance is under review.
- **Translations and tafsir:** the Arabic *At-Tafsir Al-Mukhtasar* (Siraj) is republished unmodified from **QuranEnc.com** (pinned version `47ca096b0976443ba2eab2e45cdf0fb4096a2610`). The English reader uses **Marmaduke Pickthall, The Meaning of the Glorious Koran (1930)**; the translation text is public domain (the translator died in 1936), and the digitized edition is used under its source's non-commercial terms — this site is free and ad-free and attributes the source. The Quran Foundation tafsir packs and The Clear Quran are not shipped.
- **Fonts:** Cairo is licensed under the SIL Open Font License. HafsSmart (KFGQPC Hafs Smart) is free to use, copy and distribute under its bundled EULA, but may not be sold or modified; © King Fahd Glorious Quran Printing Complex. me_quran is © 2005 Meor Ridzuan and free for non-commercial use.

## Questions

For any question about this policy, email the app owner at [mustafasayed20002@gmail.com](mailto:mustafasayed20002@gmail.com). (Optional alternative channel: the project's GitHub repository.)
