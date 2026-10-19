# Almosaly (`com.moslay`) — Full Recon Reference

Date: 2026-10-19 · Companion evidence to `docs/superpowers/plans/2026-10-19-almosaly-benchmark-decision.md`
Subject: المصلي / Almosaly — feature & technology inventory derived from shipped-artifact analysis (no runtime observation).
Not an audit of Almosaly's code quality; an inventory of what exists, so feature decisions can cite identifiers instead of impressions.

## Method & evidence

- Device: Infinix X6882, adb serial `13372704AR007777` (REA adb provider, adb 37.0.0). The analyzed copy is the **Google Play install** (`installer_package_name=com.android.vending`).
- Installed version: **17.0.8 (versionCode 10349)** · first install 2025-03-17 · last device update 2026-10-08. Play listing (ar/EG) last updated **2026-10-11**; full AR + EN store description read.
- Tooling: REA 6.7.0 CLI — JADX headless 0.7.1 (provider), Ghidra 12.1.4 available. No target execution beyond declared adb reads.
- REA evidence (all retained in the session ledger): device list `ev_2bbcda59…` · package resolve `ev_a87207f5…` · device package facts `ev_a2c7011d…` · APK pull `ev_38f94929…` · manifest `ev_16481660…` · Flutter check `ev_f1f8bfba…` · site bundle `ev_288fe91c…` · browser targets `ev_61a2ebcc…`.
- Pulled APK set (`pull-adb-package`, complete, zero failures):
  - `base.apk` — 154,676,425 B — sha256 `84d8ec49a1d08329267eea534fc16d8ae8e096634b3493e9329cc87f1e5516e6`
  - `split_config.arm64_v8a.apk` — 36,566,616 B — sha256 `d728deb5a0759f3ef57a0febfd5e631352e69be88941a5a99170ade81c51b593`
  - `split_config.xxhdpi.apk` — 17,191,849 B — sha256 `e10d0da102a5ad44f741a5134d81b233aa8367cd2ab93c89a6b4b0bb900b0b6b`
- Manifest decode: `minSdk 24` · `targetSdk 36` · `compileSdk 36` · **55** `uses-permission` · 40 activities (5 app-owned, 35 library) · 8 services (2 app-owned) · 18 receivers (10 app-owned) · 9 providers. Reported `class_count 48,392`, `resource_count 8,805`.
- Build type: **native Android (Java/Kotlin), not Flutter** (`identify-flutter-build`: `flutter_detected=false`, no `libapp.so`).
- Class census: full symbol inventory via `search-android-classes base.apk "."` (4,571,609-byte JSON retained in the session scratch dir). All module names below are observed class/package identifiers or store-listing text; UX intent is inference from those identifiers and is marked as such where it matters.

## App feature domains (identifier evidence)

1. **Prayer times & adhan** — Egyptian General Authority preset per store copy; `AzanActivity`, `AzanSettingsActivity` (9 VIEW filters), `AzanAndIqamaFragmentPagerAdapter`, `before_azan_notification` subsystem (21 classes: service + messages + read-state), `control_2015` scheduling (`ALarmControl`, `AlarmsJobSchedulerControl`, `ScheduleAzanReceiver`), `notificationsSounds`, `notifications` receivers (BOOT_COMPLETED / DATE_CHANGED / exact alarms / full-screen intent), quick setup (`QuickConfigurationActivity`), silent-mode onboarding (`onboarding.MobileSilentOnboarding`), forbidden-times screen (`ForbiddenTimesSettingsScreen`), widgets (`PaidAppWidgetProvider`, `WidgetFree/Paid(+Ar)` bindings, `HomeWidgetControl`).
2. **Fajr aid** — `Mo3eenFajrActivity`, `Mo3eenFajrSettings`, `Mo3eenFajrAnimationControl`, `fajrList` (36 classes: list rows, edit dialogs, stop settings), `alerts_firebase_dispatcher.CallFagerContactsService(+Foreground)` with `CALL_PHONE` / `MANAGE_OWN_CALLS` / `READ_CONTACTS` permissions and FCM wiring → friends-call service (inference from identifiers + permissions).
3. **Qibla (Compose rewrite in progress)** — `com.moslay.compose.features.qibla` (138 classes): `QiblaFragment`, compass screen contract (`CompassQiblaKt`, intents/states), `QiblaModule_ProvideARQiblaSensorManagerFactory` (AR sensor manager), device azimuth provider, `DirectionsInstructionEnum`, calibration `WarningState`, `LocationTracker`.
4. **Quran** — reader fragments (`mvvm.view.fragments.quran`, 85), tafseer selection (`QuranSelectTafseerFragment`), sounds (`mvvm.quran.sounds`, 26), share-as-files (`quran.share.files`), `DownloadQuranService`; **khatma system** (`KhatmaDetails/InternalDetails/Link/Notification/ReadWerd/EditKhatma` activities, `KhatmaChatAdapter`, `UpdateKhatmaEvent`/`UpdateReadEvent`, `JoinedKhatmatAdapter`, `RestoreKhatmatListener`); **memorization** (`quran_memorization`, 118 classes: plan steps, repetition types, linked-repetition help, readers, plan audio player, step-done dialogs).
5. **Azkar / tasbih / sebha** — `AzkarShareActivity`, `ZekrDialogActivity`, `AzkarSearch*`, `AzkarPagerAdapter` family, `newAzkarTypes.KnozAzkarCounter`, `new_sebha` (NewCounterFragment + `CustomSebhaView` + settings sheet), `control_2015.SebhaControl`, `FindSimilarityPercentage` (search-adjacent).
6. **Duaa** — Compose `com.moslay.compose.features.duaa` (217 classes: dashboard with daily message/categories, `duaa_settings`, `read_duaa` with awrad, sounds datasource with per-reader downloads, themes, font-size state); **social dua requests** (`doaa_requests`, 63 classes: add/details/society/amen/statistics/report, notifications, anonymous posting, `SignalRManager`) + shared comments engine (`comments`, 171 classes: comment/reply/report across community/duaa posts).
7. **Worship tracking & gamification** — `Taatk*` (TaatkFragment/Badges/Rewards/Ranking + `MosallyRewardsFragment`), Compose `almosaly_stars` (81: StarsApiService, fetch-server-time anti-cheat, `StarsAlarmReceiver`), `challenges` (97: challenge list/details, country challenges, join/leave, points `AddPoints`, statistics, `SignalRService` real-time), `rewardsByShare` (30: share points + `CountryWorshipRank`), `ramadanCompetitionCards`.
8. **Ramadan** — `ramadan_qdaa` (58: missed-fast tracking, `MainQdaaActivity`, `FastingDaysActivity`, calendar sheet, alarms, local DB), `ahkamramadan` (men/women fasting rules fragments), `ramadan_decoration` (Ramadan cards), site `/amsakiah`.
9. **Charity & payments (Compose)** — `basket_of_goodness` (415: campaigns + charities bottom sheet, goodness bank with donation archive, sadqa donate-now, zakat main/pay/saved, zakat calculator with livestock/stocks, quick-donate sheet, reminder periods), `charity_bank` (136), legacy `campaign.CampaignActivity`/`DonateNowActivity`, `fawryPayment` (98: Fawry order create/status/restore, e-wallets, payment methods, subscription-expired flows), `inapp_purchase` + `billing` (Google Play Billing 9.1.0 per manifest meta-data).
10. **Places** — `nearby_places` (73): nearest mosque list/map, nearest halal list/map, web-view results, HERE SDK (591 classes) + Google Maps/Places keys in manifest.
11. **Prayers on plane** — `prayers_on_plane` (238): flight track model/DB, `FlightAlarmReceiver`, `FlightAlarmsScheduler`, flight athkar categories/items, on-map dialogs (transit/ticket/no-internet), `FlightSupplicationsHelper`.
12. **Community & content** — `mosaly_community` (370: posts, paging, actions, one-touch helpers), `mvvm.ui.tasks_list` (tasks with hijri/gregorian calendar adapters), news (`NewsDetailsActivity`, `NewsWebView`), `TodayEventDetailsActivity`, internal mail (`MailMainActivity`, `MessageDetailsActivity`, `SendMessageActivity`), `stored_data`, `dhu_al_hija_card`, `whats_new`, surveys.
13. **Account & store** — login/signup (`LoginActivity`, `SignUpFragment`, `LoginWithEmailFragment`), `accountDeletion` (7), `free_trial` (AdsService-backed in-house ad/detail/webview + `FreeTrialBottomSheet` + FileDownloader/ZipExtractor), `PurchaseControl`, `mosalyRating`, our-apps screen, technical support.
14. **Onboarding & locale** — `on_boarding` (72), `location_onbaording` (multi-step: add city, online search, other ways, service-off, last-known-location), `LanguageSelectActivity` + `LanguageChangedReceiver`; store copy advertises extra locales (ru/fr/tr/fa).
15. **Voice** — `speechRec` (16: DroidSpeech engine + recognition bar UI). Exact usage unverified.
16. **Background** — `foreground_service.RunningService`, WorkManager, FCM (`MyFirebaseMessagingService`, legacy GCM C2D), `AlarmsWorkSchedulerService`.

## Technology stack observed

- **Architecture**: legacy MVVM + data-binding (`com.moslay.databinding` = 1,429 generated classes) with an **in-progress Jetpack Compose migration** (`com.moslay.compose` = 1,526 classes; per-feature `di/domain/data/presentation` + Hilt).
- **Libraries** (class-count roots): Hilt (Dagger 138), Room, DataStore, RxJava (1,628), Media3 (859) + Media2, Paging, WorkManager, CameraX, Amazon AWS SDK (1,048), HERE SDK (591), JSoup, Picasso, Koush ion, Emoji2, ProfileInstaller.
- **Firebase**: Messaging/Storage/RemoteConfig/DynamicLinks/AppCheck present; `firebase_crashlytics_collection_enabled=false` and `firebase_performance_collection_enabled=false` in manifest.
- **Ads / monetization SDKs**: Google Ads (App ID published in manifest), Facebook Audience Network, MBridge, Bytedance Pangle 8.2.0.4, InMobi, Fyber, IronSource, Unity Ads, Vungle, PubMatic, Criteo, plus an in-house ad service (`free_trial`).
- **Attribution / analytics**: Adjust (`adjust-lifecycle-provider`), Facebook SDK, CellRebel, `madar_analytics` (first-party).
- **Payments**: Google Play Billing 9.1.0 + Fawry + e-wallets.
- **In-app messaging**: `com.madar.inappmessaginglibrary` (first-party, Room-backed).
- **Official website stack** (from REA web-bundle capture, 12/12 scripts, no API endpoints found): jQuery 3 + jQuery-UI + Bootstrap + owl.carousel + lazyload + monthpicker + intl-tel-input + jquery.validate; server-rendered pages; `/mawaquit`, `/amsakiah`, `/azkar`, `/khatma/<month>`, `/Live`, `/Favorite`, `/Category` + 20 content categories; store links behind an AppsFlyer OneLink (`almosaly.go.link`).

## Manifest highlights worth recording

- Permission groups: location (fine/coarse/**background**), telephony (`CALL_PHONE`, `READ_PHONE_STATE`, `READ_PHONE_NUMBERS`, `MANAGE_OWN_CALLS`, `FOREGROUND_SERVICE_PHONE_CALL`), contacts, camera + `RECORD_AUDIO`, alarms (`SCHEDULE_EXACT_ALARM`, `SET_ALARM`, receiver `RECEIVE_BOOT_COMPLETED`), `USE_FULL_SCREEN_INTENT`, overlay (`SYSTEM_ALERT_WINDOW`, `ACTION_MANAGE_OVERLAY_PERMISSION`), `WRITE_SETTINGS`/`WRITE_SECURE_SETTINGS`, billing, ad IDs (`AD_ID`, ADSERVICES set).
- Exported app-owned components: `AzanSettingsActivity` (deep links), `KhatmaLinkActivity`, `WebviewActivity`, `ScheduleAzanReceiver`, `RunNotificationAsReciever`, `MosallyProvider` (content provider), `PaidAppWidgetProvider`.
- Google Maps/Places API key and AdMob App ID are embedded in the manifest as expected for in-APK keys (key material **not reproduced** in this document; only its presence is recorded).
- Obfuscated third-party SDK root `com.sshqwj.pjxcjz159222` (APPID 252940) present; not analyzed.

## Method limitations

- Static / shipped-artifact evidence only — no runtime observation, no network capture, no decompiled business-logic claims.
- Library-provided components are attributed to their vendored SDKs; whether every advertised SDK capability is enabled at runtime was not verified.
- UX intent for feature names (e.g., "Mo3een Fajr = friends-call service") is an inference from identifiers + permissions + store copy, not observed behavior; where the benchmark decision depends on intent, the decision doc says so.
