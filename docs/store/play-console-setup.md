# Play Console Setup — Quran Yahdi v1.0.0

> Owner-run runbook for the first Google Play submission. Every value here is copied from a
> verified in-repo source; anything that can only be answered inside Play Console is marked
> `PLAY-CONSOLE-ONLY`. Nothing in this document is a Play policy claim that was not checked
> against the console at submission time.

Last updated: 2026-10-24 · Android only for this submission (no iOS/web listing).

## 1. App identity

| Field | Value | Source |
|---|---|---|
| Package name | `com.mostafasayed.quranyahdi` | `android/app/build.gradle:49` |
| Version name | `1.0.0` | `pubspec.yaml` (`version: 1.0.0+3`) |
| Version code | `3` | `pubspec.yaml` (`version: 1.0.0+3`) — exceeds the 2026-10-24 `+2` build and the 2026-10-22 `+1` build whether or not either was uploaded |
| minSdk | `24` | `docs/campaign-ledger.md:878` |
| targetSdk | `36` | `docs/campaign-ledger.md:878` |
| Release AAB path | `build/app/outputs/bundle/release/app-release.aab` | Gradle output |
| Last verified signed artifact (2026-10-24, `+2`) | AAB `68,195,926 B` · SHA-256 `90745181…CB713` · APK `69,497,234 B` · SHA-256 `61C95D0D…B63987` · versionCode `2` · `jarsigner` + `apksigner` V2 verified · cert `CN=Mostafa Sayed, OU=Quran Yahdi, O=Quran Yahdi, L=Cairo, ST=Cairo, C=EG` (SHA-256 `DB:7F:FE:F4…46:85`) | This session's rebuild |
| Keystore | `C:\Users\ASUS\keystores\quran-yahdi-release.jks` (`android/key.properties` is gitignored) | `docs/campaign-ledger.md:877` |

> The `+3` artifact must be rebuilt and re-verified (size, SHA-256, `apksigner`) before upload; the `+2` row above is historical.

- [x] Package name confirmed against the build script, not the store listing.
- [ ] Confirm the AAB was built after the latest code change (`git log -1` at build time).
- [ ] Keep the keystore + passwords in a password manager and on an offline USB (owner-owed, `docs/campaign-ledger.md:877`).

## 2. Store listing

| Console field | Value / source |
|---|---|
| App name | `docs/store/listing-en.md` (EN) · `docs/store/listing-ar.md` (AR) — title blocks, char-counted |
| Short description | `docs/store/listing-en.md` / `listing-ar.md` — short-description blocks |
| Full description | `docs/store/listing-en.md` / `listing-ar.md` — full-description blocks |
| Support email | `mustafasayed20002@gmail.com` |
| Privacy policy (AR) | https://quranyahdi.pages.dev/privacy/ |
| Privacy policy (EN) | https://quranyahdi.pages.dev/en/privacy/ |
| Category | `Books & Reference` (alternative: `Education`) |
| Tags | Quran, recitations, prayer times, qibla, adhkar, duas, offline, Islamic |
| Contact website (optional) | https://quranyahdi.pages.dev/ |
| Default language | Arabic (`ar`), with the English listing as a second locale (suggestion — owner choice) |

- [x] Both privacy URLs return HTTP 200 (owner-verified).
- [ ] Re-check both URLs *after* the next web deploy, since the pages render `PRIVACY.md` / `PRIVACY.en.md` at build time.

## 3. Declarations

| Declaration | Answer | Note |
|---|---|---|
| App access | **All features available without login** | No credentials to provide to reviewers; no account system exists. |
| Ads | **No ads** | No ads SDK in the dependency set. |
| Content rating questionnaire | **Everyone / PEGI 3 — religious reference content** | Expected outcome; the actual rating is issued by IARC after the questionnaire. No violence, gambling, user-generated content, or purchases. |
| Target audience | **General audience; not child-directed** | Do not opt into the Families / Designed for Families program. |
| News app | **No** | No news content or news-style publishing. |
| Government app | **No** | Not affiliated with any government entity. |
| Health app | **No** | No health features, sensors, or health data. |
| Financial features | **No** | The zakat calculator is informational only: no transactions, no payments, no financial advice, no financial data. |
| Exact alarms | **No Play declaration required** | The manifest declares `SCHEDULE_EXACT_ALARM` (`android/app/src/main/AndroidManifest.xml:9`), a user-granted special access the user enables in system settings. `USE_EXACT_ALARM` is **not** declared. |

- [ ] Enter the declarations above in Play Console (`PLAY-CONSOLE-ONLY` — cannot be set from the repo).
- [ ] Re-read the exact-alarm row before submitting: if a future build adds `USE_EXACT_ALARM`, this answer changes.

## 4. Data safety

Primary source: `docs/store/data-safety-form-answers.md` (permission census + line-by-line answers).

| Section | Answer |
|---|---|
| Does the app collect or share required user data types? | **No** |
| Data shared with third parties | **None** |
| Data stored remotely | **None** — everything stays on device |
| Data encrypted in transit | N/A — nothing is transmitted |
| Deletion | Uninstalling the app deletes all local data; no remote copy exists |
| Account deletion URL | N/A — no accounts |

- [x] Answers already derived from `PRIVACY.md` / `PRIVACY.en.md` and the live manifest census.
- [ ] Paste the answers into the console form (`PLAY-CONSOLE-ONLY`).

## 5. Assets checklist

| Asset | Requirement | Status |
|---|---|---|
| Phone screenshots | 2–8 per type | **11 captured**, 1080×2160, at `docs/store/screenshots/` (`01-home` … `11-settings`) — pick 2–8 and order them by the priority in `listing-en.md` / `listing-ar.md` |
| App icon | 512×512 PNG | `docs/store/app-icon-512.png` — 512×512, byte copy of `assets/icons/app_icon_2.png` (not resized) |
| Feature graphic | 1024×500 PNG/JPG | `docs/store/feature-graphic-1024x500.png` — 1024×500, built from the real app icon + Cairo type |
| Tablet screenshots | 7"/10" | **None** — not planned for this submission (optional on Play) |
| Localized screenshot sets | per locale | **None** — one phone set serves both `ar` and `en` |

- [ ] Pick and order the 2–8 screenshots (owner decision; first slot should be `01-home.png`).
- [ ] `05-ayah-sheet.png` shows the tafsir content that is no longer shipped — recapture it or do not select it.
- [x] Land `docs/store/feature-graphic-1024x500.png` before uploading (present, 1024×500).

## 6. Release checklist

- [ ] Set `PUBLISH_RELEASE=true` (or `-PpublishRelease=true`) for the store-bound build — without it the Gradle build stays debug-signed by design; with it and no keystore the build **fails** instead of shipping a debug-signed artifact.
- [ ] Build the bundle: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
- [ ] Verify the signer before upload: `jarsigner -verify -verbose -certs` on the AAB; expect `CN=Mostafa Sayed, OU=Quran Yahdi, O=Quran Yahdi, L=Cairo, ST=Cairo, C=EG` and record the certificate SHA-256.
- [ ] Confirm the versionCode rule: the uploaded code **must exceed every versionCode previously uploaded to any track**. Current build is `1.0.0+3` → versionCode `3`; nothing on this branch is published, but the earlier `+2`/`+1` builds may already sit on a track — **re-check the highest versionCode in Play Console before every upload** and bump `pubspec.yaml` again if `3` is not strictly greater.
- [ ] Upload to an internal/staging track first and install from Play on a real device (smoke: launch, open a surah, play a recitation, prayer times, qibla).
- [ ] Closed testing: new personal developer accounts require **12 testers for 14 continuous days** before production access — **verify the current policy in Play Console** (`PLAY-CONSOLE-ONLY`, rules change).
- [ ] Promote to production and complete the staged rollout.
- [ ] Never commit the keystore or `android/key.properties` (both gitignored).

## 7. Open blockers

All licensing items are `OPEN-FOR-OWNER` — recorded in `docs/store/licensing-matrix.md`, **not resolved here**.

| # | Blocker (source: `licensing-matrix.md` → OPEN-FOR-OWNER) | Verified status (2026-10-24) |
|---|---|---|
| 1 | `HafsSmart_08.ttf` + `me_quran.ttf` mushaf font licenses | **AMBER** — HafsSmart EULA permits use/copy/distribute (shipped in-app + attribution); `me_quran` is non-commercial only |
| 2 | quranenc.com text terms for `ara-sirajtafseer` | **AMBER** — republish allowed with attribution, version, no modification; prove the edition |
| 3 | Saheeh International `eng-safiurrahmanalm` publisher terms | **AMBER** — Tanzil: non-commercial only; replaced in the app catalog by Pickthall (`eng-mohammedmarmadu`) on 2026-10-24, same Tanzil clause |
| 4 | The Clear Quran `eng-mustafakhattabg` | **RED** — publisher requires prior written consent for any reproduction |
| 5 | Bukhari EN translator license for `eng-bukhari` | **RED** — no license grant (Muhsin Khan; upstream `source` empty) |
| 6 | Tafsir data provenance for the `spa5k/tafsir_api` packs | **RED** — QF terms require a commercial license for content packages |
| 7 | mp3quran.net terms for streaming/downloading | **AMBER/GREEN** — use/copy allowed with attribution; reciter rights remain |
| 8 | `eng-muslim` (Abdul Hamid Siddiqui) | **RED/UNVERIFIED** — no license grant |

Full quotes and the per-pack verdict: `docs/store/licensing-verification-2026-10-24.md`.

**App catalog:** the six RED packs were withdrawn on 2026-10-24 (catalog v1.2 ships 3
packs: `ara-sirajtafseer`, `eng-mohammedmarmadu` (Pickthall), `ara-bukhari`). **Web:**
`web/src/lib/content-packs.ts` ships only the two licensed translations; the six were
withdrawn there too. The `HafsSmart` EULA + attribution are shipped in-app (Settings →
Licenses & sources).

Play-Console-only items (cannot be completed from the repo):

- Data safety form submission, content rating questionnaire, target-audience selection, and the ads declaration must be entered in the console (`PLAY-CONSOLE-ONLY`).
- Closed-testing policy (testers/days) must be re-read in the console at submission time (`PLAY-CONSOLE-ONLY`).
- The feature graphic is present (`docs/store/feature-graphic-1024x500.png`, 1024×500).
