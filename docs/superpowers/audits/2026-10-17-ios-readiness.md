# iOS-Readiness Audit — 2026-10-17

- **Repo / branch / HEAD (actual):** `E:\old_flutter\Quran-App-master` · `main` · `28db71dfa17b8a3b8d426228ddf74253e16e66fd`
- **Method:** static source audit on Windows; no macOS build; no network; no `pod install`; no `xcodebuild`; no code/test/plan/ledger edits.
- **Scope:** iOS project config, Info.plist/permissions, plugin minimum OS, notifications, audio, location, sensors, storage/DB, network/ATS, assets/branding, localization/RTL, privacy/compliance, build/CI, Android→iOS parity.
- **Explicit non-goals:** Android changes, code fixes, fix wave, device work, Supabase, signing (W7c), ledger/plan edits, commits, push.

## Verdict summary

Counts are one primary area per finding; the `Totals` row is the unique finding count. FLAG cells mark every area the same unverifiable item touches, so the FLAG column can exceed the seven unique FLAGs.

| Area | Verdict | P0 | P1 | P2 | FLAG |
|---|---|---:|---:|---:|---:|
| A. Xcode project configuration | GAP | 0 | 2 | 1 | 1 |
| B. Info.plist & platform permissions | GAP | 0 | 0 | 2 | 0 |
| C. Flutter/plugin minimum-OS compatibility | GAP | 0 | 1 | 0 | 1 |
| D. Notifications (functional parity) | GAP | 0 | 3 | 1 | 1 |
| E. Audio & background execution | PASS | 0 | 0 | 0 | 1 |
| F. Location | PASS | 0 | 0 | 0 | 1 |
| G. Sensors/qibla | PASS | 0 | 0 | 0 | 1 |
| H. Storage, DB, files | PASS | 0 | 0 | 1 | 1 |
| I. Network/ATS | PASS | 0 | 0 | 0 | 1 |
| J. Assets & branding | GAP | 1 | 0 | 1 | 0 |
| K. Localization/RTL | GAP | 0 | 0 | 2 | 1 |
| L. Privacy/compliance | GAP | 0 | 0 | 1 | 2 |
| M. Build/CI/verification path | GAP | 0 | 1 | 1 | 1 |
| N. Android→iOS parity matrix | GAP | 0 | 0 | 0 | 0 |
| **Totals (unique)** | **GAP** | **1** | **7** | **10** | **7** |

Top-level verdict: the app is **not yet App Store-ready**. One P0 (marketing icon alpha), seven P1s (notifications dead on iOS, permission path missing, no notification delegate, stale iOS 12 deployment target, placeholder bundle id, no UIScene lifecycle, no macOS CI), and ten P2 polish/compliance items.

## Findings

### P0-1 — App Store marketing icon contains an alpha channel (release blocker)

- **Evidence:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` is 1024×1024 `Format32bppArgb`; a pixel scan found `minAlpha=0` (transparent pixels). `Contents.json:112-114` registers that exact file for `ios-marketing`. The generation config in `pubspec.yaml:35-38` enables `android: true` and `ios: true` but never sets `remove_alpha_ios`. Local package doc: `flutter_launcher_icons-0.14.4/lib/ios.dart:129` — “WARNING: Icons with alpha channel are not allowed in the Apple App Store. Set "remove_alpha_ios: true" to remove it.”; `README.md:118` documents the option.
- **Impact:** App Store upload validation rejects the large icon (“can’t be transparent nor contain an alpha channel”), so the build cannot be shipped as-is.
- **Exact fix (NOT applied):** add to the existing `flutter_launcher_icons:` block in `pubspec.yaml` after line 38:
  ```yaml
  remove_alpha_ios: true
  background_color_ios: "#f1ead7"
  ```
  then run `dart run flutter_launcher_icons` and verify every `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` is RGB (no alpha channel) and the 1024 file is exactly 1024×1024.

### P1-1 — Notification plugin initialization throws on iOS, so every reminder is silently dead

- **Evidence:** `lib/features/notifications/data/notifications_binding.dart:55-58` passes only `android: AndroidInitializationSettings(defaultIcon)` to `InitializationSettings`; there is no `iOS:` entry. The plugin’s Dart API rejects that on iOS: `flutter_local_notifications-22.3.2/lib/src/flutter_local_notifications_plugin.dart:142-147` — `if (settings.iOS == null) throw ArgumentError('iOS settings must be set when targeting iOS platform.')`. The binding catches it at `notifications_binding.dart:71-73` and leaves `_ready = false`; `scheduleAll` then returns early at `:121-123`.
- **Impact:** on iOS no local notification is initialized or scheduled — prayer reminders and the azkar reminder do nothing. The app does not crash (deliberate best-effort catch), which makes the gap silent.
- **Exact fix (NOT applied):** in `notifications_binding.dart:55-58`, add:
  ```dart
  iOS: DarwinInitializationSettings(
    requestAlertPermission: false,
    requestSoundPermission: false,
    requestBadgePermission: false,
  ),
  ```
  and extend `NotificationDetails` at `:61-69` with `iOS: const DarwinNotificationDetails()`. Keep the request flags false so boot does not prompt; P1-2 owns the request-on-opt-in path.

### P1-2 — No iOS notification-permission path exists

- **Evidence:** `requestBootPermission` resolves only `AndroidFlutterLocalNotificationsPlugin` (`notifications_binding.dart:89-91`) and calls only Android APIs (`:92`, `:99`). `ensurePermissions` does the same (`:109-117`) and returns `true` for iOS at `:111` without requesting anything. A repository-wide grep found no `DarwinInitializationSettings`, `IOSFlutterLocalNotificationsPlugin`, or `requestPermissions` in `lib/`. The plugin exposes the iOS API at `platform_flutter_local_notifications.dart:759-798` (`requestPermissions(alert/sound/badge)` and `checkPermissions()`).
- **Impact:** even after P1-1 is fixed, iOS never obtains authorization; `ensurePermissions()` reports success and the settings UI never shows the intended “permission denied” hint. Notifications remain invisible.
- **Exact fix (NOT applied):** in `ensurePermissions`, before/after the Android branch:
  ```dart
  final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  if (ios != null) {
    final granted = await ios.requestPermissions(
      alert: true, sound: true, badge: true);
    return granted ?? false;
  }
  ```
  In `requestBootPermission`, add the same resolution and mirror the Android grace:
  ```dart
  final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  if (ios != null) {
    final enabled = (await ios.checkPermissions())?.isEnabled ?? true;
    if (shouldRequestBootPermission(
        notificationsEnabled: enabled, azkarEnabled: azkarEnabled)) {
      await ios.requestPermissions(alert: true, sound: true, badge: true);
    }
    return;
  }
  ```

### P1-3 — AppDelegate never assigns the UNUserNotificationCenter delegate

- **Evidence:** `ios/Runner/AppDelegate.swift:4-12` is the 13-line template: `GeneratedPluginRegistrant.register(with: self)` then `super.application(...)`. No `UNUserNotificationCenter.current().delegate` assignment. The plugin README requires it: `flutter_local_notifications-22.3.2/README.md:473-482` (“Add the following lines to the `application:didFinishLaunchingWithOptions:` … `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate`”).
- **Impact:** notifications fired while the app is in the foreground are not presented by the plugin’s `willPresentNotification` implementation (`FlutterLocalNotificationsPlugin.m:1033-1065`), and tap callbacks are not routed through it.
- **Exact fix (NOT applied):** in `ios/Runner/AppDelegate.swift` add `import UserNotifications` and, inside `didFinishLaunchingWithOptions` before `GeneratedPluginRegistrant.register(with: self)`:
  ```swift
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
  ```

### P1-4 — iOS deployment target 12.0 conflicts with the installed Flutter template (15.0) and two plugins (13.0)

- **Evidence:** `ios/Runner.xcodeproj/project.pbxproj:349`, `:475`, `:526` all set `IPHONEOS_DEPLOYMENT_TARGET = 12.0`; `ios/Flutter/AppFrameworkInfo.plist:23-24` says `MinimumOSVersion` `12.0`. The installed Flutter 3.47.5 template sets `15.0` at `C:\src\flutter\packages\flutter_tools\templates\app\ios.tmpl\Runner.xcodeproj\project.pbxproj.tmpl:383`, `:513`, `:565`. `flutter_local_notifications-22.3.2/ios/flutter_local_notifications.podspec:19` requires iOS 13.0 and `sensors_plus-7.1.1/ios/sensors_plus.podspec:19` requires iOS 13.0. Flutter auto-migrates old targets on build: `flutter_tools/lib/src/ios/mac.dart:154-159` registers `IOSDeploymentTargetMigration`, and `ios/migrations/ios_deployment_target_migration.dart:88-118` rewrites 8/9/11/12/13/14 to `15.0` and prints “Updating minimum iOS deployment target to 15.0.” A manual `pod install` before that migration fails with CocoaPods’ “required a higher minimum deployment target” path (`macos/cocoapods.dart:422-466`).
- **Impact:** the repo’s declared floor is stale; the first macOS build mutates `project.pbxproj` and `AppFrameworkInfo.plist` (dirty tree), and a manual `pod install` fails against `sensors_plus`/`flutter_local_notifications`.
- **Exact fix (NOT applied):** commit the migration explicitly: set `IPHONEOS_DEPLOYMENT_TARGET = 15.0;` at `project.pbxproj:349`, `:475`, `:526`; remove the whole `MinimumOSVersion` key from `ios/Flutter/AppFrameworkInfo.plist` (the migration’s replacement at `ios_deployment_target_migration.dart:70-82`), or set it to `15.0`; when the Podfile is generated, set `platform :ios, '15.0'` (template `templates/cocoapods/Podfile-ios:2` is commented out). Then re-run `flutter pub get` on macOS and verify no further migration output.

### P1-5 — Bundle identifier is the placeholder `com.example.quranApp`, not the project’s intended id

- **Evidence:** Runner target: `project.pbxproj:371` (Profile), `:550` (Debug), `:572` (Release) — `PRODUCT_BUNDLE_IDENTIFIER = com.example.quranApp;`; RunnerTests: `:387`, `:404`, `:419` — `com.example.quranApp.RunnerTests`. The locked design records the intended id: `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md:71` — “App ID | `com.mostafasayed.quranyahdi` (Android + iOS reserved same)”. Android already uses it: `android/app/build.gradle:36` — `applicationId = "com.mostafasayed.quranyahdi"`.
- **Impact:** the iOS app cannot be signed/registered under the owner’s team with a placeholder prefix; App Store identity drifts from Android and from the design decision. Signing/App Store Connect work must rename the id anyway.
- **Exact fix (NOT applied):** set all six occurrences to `com.mostafasayed.quranyahdi` / `com.mostafasayed.quranyahdi.RunnerTests`, then create/verify the App ID in the Apple Developer account (FLAG-2).

### P1-6 — iOS UIScene lifecycle is not adopted while the installed Flutter template requires it

- **Evidence:** `ios/Runner/Info.plist` has no `UIApplicationSceneManifest` (keys end at `UIApplicationSupportsIndirectInputEvents`/`UIStatusBarHidden`, `:52-55`); the `ios/` tree has no `SceneDelegate.swift`; `ios/Runner/AppDelegate.swift:4-12` uses the legacy `GeneratedPluginRegistrant.register(with: self)` pattern. The installed Flutter 3.47.5 template ships `Runner/SceneDelegate.swift` (4 lines, `class SceneDelegate: FlutterSceneDelegate {}`) and `Runner/Info.plist.tmpl:29-50` (`UIApplicationSceneManifest`, `UISceneDelegateClassName = $(PRODUCT_MODULE_NAME).SceneDelegate`); the template `AppDelegate.swift:5-14` uses `FlutterImplicitEngineDelegate` and registers in `didInitializeImplicitFlutterEngine`. The plugin README also points at the UIScene migration guide (`flutter_local_notifications-22.3.2/README.md:551`, `:579`). **POLICY (verify against current Apple guidance):** the iOS 26 SDK UIScene requirement is an external platform policy; it cannot be proven from this repo.
- **Impact:** if the archive is built with the iOS 26 SDK as required by current Xcode, a non-UIScene app may fail to launch or be rejected. Even before that policy, the project is two Flutter template generations behind.
- **Exact fix (NOT applied):** apply Flutter’s UIScene migration (breaking-change guide referenced by the plugin): add `ios/Runner/SceneDelegate.swift` with `class SceneDelegate: FlutterSceneDelegate {}`; add the `UIApplicationSceneManifest` dictionary from `Info.plist.tmpl:29-50` to `ios/Runner/Info.plist`; update `AppDelegate.swift` to `FlutterAppDelegate, FlutterImplicitEngineDelegate` and register plugins in `didInitializeImplicitFlutterEngine`. Verify on macOS with the current iOS SDK.

### P1-7 — CI has no macOS/iOS build or test job

- **Evidence:** `.github/workflows/ci.yml:7-19` (`analyze-test`, `runs-on: ubuntu-latest`) and `:24-44` (`release-artifact`, Android APK/AAB, `runs-on: ubuntu-latest`). No macOS runner, no `pod install`, no `xcodebuild`, no `flutter build ios`.
- **Impact:** every iOS build break (deployment target, pods, Swift/AppDelegate, native assets) is discovered only in a manual Mac session; the Android-green gate gives false confidence.
- **Exact fix (NOT applied):** add an `ios-build` job:
  ```yaml
  ios-build:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter gen-l10n
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: cd ios && pod install
      - run: flutter build ios --release --no-codesign
      - run: flutter test
  ```
  A `flutter build ipa` job must be separate and gated on signing secrets (FLAG-2).

### P2-1 — iOS display name is the English placeholder “Quran App”; Android is Arabic

- **Evidence:** `ios/Runner/Info.plist:7-8` — `CFBundleDisplayName` = `Quran App`; `:15-16` — `CFBundleName` = `quran_app`. Android app label is Arabic: `android/app/src/main/AndroidManifest.xml:11` — `android:label="قرآن يَهدي"`. The app’s Arabic name is `app_ar.arb:1` (`appName` = `قرآن يَهدي`); README uses it at `README.md:1`.
- **Impact:** the home-screen name differs between platforms and from the product name; visible store/device inconsistency.
- **Exact fix (NOT applied):** set `CFBundleDisplayName` to `قرآن يَهدي` (or localize it via `InfoPlist.strings` as in P2-2); leave `CFBundleName` as the internal ASCII name or change it to `QuranYahdi`.

### P2-2 — iOS localization metadata is absent (no `CFBundleLocalizations`, no `ar.lproj`/`en.lproj`, no `InfoPlist.strings`)

- **Evidence:** `ios/Runner/Info.plist` has no `CFBundleLocalizations` key; the only localized resource is `ios/Runner/Base.lproj/` (Main/LaunchScreen); the `ios/` tree has no `ar.lproj` or `en.lproj` and no `InfoPlist.strings`. `project.pbxproj:186` sets `developmentRegion = en;` and `:188-191` lists `knownRegions = (en, Base);`. The Flutter app supports both locales (`lib/app/app.dart:19`, `supportedLocales: [Locale('ar'), Locale('en')]`) and all 118 ARB keys exist in both files (`lib/l10n/app_ar.arb:1`, `lib/l10n/app_en.arb:1`; 118/118 parity).
- **Impact:** iOS Settings → app language does not list Arabic; the Arabic-only `NSLocationWhenInUseUsageDescription` (`Info.plist:46-47`) is shown untranslated to English users; the display name is not localized.
- **Exact fix (NOT applied):** add to `Info.plist` a `CFBundleLocalizations` array with `ar` and `en`; add `ios/Runner/ar.lproj/InfoPlist.strings` and `ios/Runner/en.lproj/InfoPlist.strings` containing localized `CFBundleDisplayName` and `NSLocationWhenInUseUsageDescription`; add `ar` and `en` to `knownRegions` at `project.pbxproj:188-191`; add the new `.strings` files to the Runner target in Xcode.

### P2-3 — No app-level `PrivacyInfo.xcprivacy`; one used SDK declares no required-reason APIs while calling `systemUptime`

- **Evidence:** the `ios/` tree contains no `PrivacyInfo.xcprivacy` (only `Assets.xcassets`, storyboards, Swift files). Bundled manifests that do exist: `flutter_local_notifications-22.3.2/ios/flutter_local_notifications/Sources/flutter_local_notifications/PrivacyInfo.xcprivacy` (declares `NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`), `geolocator_apple-2.3.15/darwin/geolocator_apple/Sources/geolocator_apple/PrivacyInfo.xcprivacy`, and `sensors_plus-7.1.1/ios/sensors_plus/Sources/sensors_plus/PrivacyInfo.xcprivacy` (14 lines, empty `NSPrivacyAccessedAPITypes`). But `sensors_plus-7.1.1/ios/sensors_plus/Sources/sensors_plus/FPPStreamHandlerPlus.swift:18` calls `ProcessInfo.processInfo.systemUptime`. `path_provider_foundation 2.6.0` is pure Dart FFI (`pubspec.yaml:14-18`, `dartPluginClass`), so it ships no manifest; `just_audio`, `audio_service`, `audio_session`, and `sqlite3` ship none in the local cache. **POLICY (verify against current Apple guidance):** required-reason API enforcement and accepted reason codes.
- **Impact:** App Store static analysis can flag undeclared required-reason API use (notably `systemUptime` through `sensors_plus`); privacy nutrition answers are harder to defend without an app manifest.
- **Exact fix (NOT applied):** add `ios/Runner/PrivacyInfo.xcprivacy` with `NSPrivacyTracking=false`, empty `NSPrivacyTrackingDomains`, empty `NSPrivacyCollectedDataTypes`, and `NSPrivacyAccessedAPITypes` entries: `NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1` (flutter_local_notifications), `NSPrivacyAccessedAPICategorySystemBootTime` / `35F9.1` (sensors_plus `systemUptime`), and—if static analysis flags SQLite/file timestamps—`NSPrivacyAccessedAPICategoryFileTimestamp` / `C617.1`. Add the file to the Runner target’s Copy Bundle Resources and confirm the exact reason codes against current Apple guidance.

### P2-4 — `ITSAppUsesNonExemptEncryption` is absent from Info.plist

- **Evidence:** `ios/Runner/Info.plist` has no `ITSAppUsesNonExemptEncryption` key (full key list ends at `:52-55`). The app’s network use is HTTPS-only (`lib/features/recitation/data/reciter_repository.dart:63-71`; `lib/features/library/data/library_catalog.dart:17`, `:79`). **POLICY (verify against current Apple guidance).**
- **Impact:** App Store Connect asks the export-compliance question for every upload; no runtime impact.
- **Exact fix (NOT applied):** add `<key>ITSAppUsesNonExemptEncryption</key><false/>` to `ios/Runner/Info.plist` (standard HTTPS is exempt), subject to the owner’s confirmation.

### P2-5 — Audio and library downloads live in iCloud-backed Application Support with no backup exclusion

- **Evidence:** both roots resolve to `getApplicationSupportDirectory()`: `lib/app/bootstrap.dart:21-29` (`defaultAudioRootResolver`, `defaultLibraryRootResolver`); audio files go under `<root>/audio/<rowId>/…` (`lib/features/recitation/data/audio_downloader.dart:52-66`); packs go under `<root>/library/<packId>.json` (`lib/features/library/data/pack_downloader.dart:133-145`). A repository grep found no `NSURLIsExcludedFromBackupKey` / `excludedFromBackup`. The catalog includes packs up to 82 MB (`assets/data/library_catalog.json:1`, `en-tafisr-ibn-kathir` approxSizeMb 82.0).
- **Impact:** downloaded recitations and multi-MB packs are included in iCloud/iTunes backups, inflating user backup size; there is no iOS equivalent of Android’s `android:allowBackup="false"` (`AndroidManifest.xml:14`).
- **Exact fix (NOT applied):** add a small MethodChannel in `AppDelegate.swift` (or a Swift helper invoked from `bootstrap.dart`) that sets `URLResourceValues.isExcludedFromBackup = true` on `<Application Support>/audio` and `<Application Support>/library` after creation; call it once after `defaultAudioRootResolver`/`defaultLibraryRootResolver` succeed. Alternatively, accept the backup exposure and document it in `PRIVACY.md`.

### P2-6 — `Podfile` / `Podfile.lock` are not committed; first Mac build mutates the tree

- **Evidence:** the `ios/` tree has no `Podfile` and no `Podfile.lock`. Flutter auto-creates the Podfile: `flutter_tools/lib/src/macos/cocoapods.dart:251-267` (`setupPodfile` copies `templates/cocoapods/Podfile-ios` when absent). `ios/.gitignore` ignores `Pods/` but not `Podfile`/`Podfile.lock`.
- **Impact:** no reproducible pod resolution; the first `flutter build ios` creates untracked files and edits the Flutter xcconfigs, producing a dirty tree at the start of every fresh checkout.
- **Exact fix (NOT applied):** on macOS run `pod install`, then commit `ios/Podfile` and `ios/Podfile.lock` (keep `Pods/` ignored); include the Podfile’s `platform :ios, '15.0'`.

### P2-7 — Launch screen uses a single beige background for both appearances and a white storyboard view background

- **Evidence:** `ios/Runner/Base.lproj/LaunchScreen.storyboard:22` sets the view background to white (`red="1" green="1" blue="1"`); `:19-20` overlays full-screen `LaunchBackground` and centered `LaunchImage`; `:40-42` declares `LaunchBackground` 1×1 and `LaunchImage` 512×512. The measured `LaunchBackground.imageset/background.png` pixel is ARGB(255, 241, 234, 215) = `#F1EAD7`, matching the splash color in `pubspec.yaml:54`. `flutter_native_splash` is enabled for iOS at `pubspec.yaml:53-57`.
- **Impact:** no dark-mode launch variant; a brief white view edge is possible if the image is not laid out before first frame. Cosmetic, not a blocker.
- **Exact fix (NOT applied):** set the storyboard view background color to `#F1EAD7` (or add an appearance-aware background image) and, if dark launch is desired, add a dark-appearance `LaunchBackground` asset.

### P2-8 — `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` is set to `AppIcon` instead of `YES`

- **Evidence:** `project.pbxproj:430` (project Debug) and `:487` (project Release) — `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon;`. The Profile config correctly has `YES` at `:310`, and the Flutter template has `YES` at `templates/app/ios.tmpl/Runner.xcodeproj/project.pbxproj.tmpl:344`, `:468`, `:526`.
- **Impact:** malformed boolean build setting; harmless today but can suppress or confuse generated asset symbols and is clearly a local edit accident.
- **Exact fix (NOT applied):** change `:430` and `:487` to `YES`.

### P2-9 — Notification cold-start launch details are not read; v1 lands on home by default

- **Evidence:** repository-wide grep found no `getNotificationAppLaunchDetails` in `lib/`. The plugin documents that `onDidReceiveNotificationResponse` cannot handle a launch and that `getNotificationAppLaunchDetails()` must be used (`flutter_local_notifications-22.3.2/README.md:755`, `:1130`). The running-app tap path is wired: `lib/main.dart:36-38` passes `onTap: () => AppRouter.router.go('/home')`; the router’s default is home: `lib/app/router.dart:69` — `initialLocation: '/home'`.
- **Impact:** for v1 (single home destination) this is acceptable: a cold-start tap opens the app at home anyway. It becomes a real gap when per-type routes/payloads are added.
- **Exact fix (NOT applied):** after `NotificationsBinding.init` in `main.dart`, call `getNotificationAppLaunchDetails()` and route to `/home` (or a future per-payload route) when `didNotificationLaunchApp` is true; add `payload` when scheduling.

### P2-10 — Reminder texts are composed in Arabic at schedule time regardless of app locale

- **Evidence:** `lib/features/notifications/data/reminder_scheduling.dart:28` — `final loc = lookupAppLocalizations(const Locale('ar'));`. The app itself also pins Arabic (`lib/app/app.dart:18`), while EN strings exist (`lib/l10n/app_en.arb:1`, 118 keys). The helper named in the fix is also AR-pinned today: `lib/core/l10n/platform_localizations.dart:9-10` returns `lookupAppLocalizations(const Locale('ar'))`.
- **Impact:** an English-configured device still receives Arabic notification titles/bodies; text cannot be localized at fire time once the app is dead (disclosed v1 limitation). Same behavior on Android, so parity is maintained.
- **Exact fix (NOT applied):** first un-pin `platformLocalizations()` (`lib/core/l10n/platform_localizations.dart:9-10`) so it resolves the active locale, then compose reminders with it and re-schedule on locale change; or explicitly document Arabic-only notifications for v1.

### FLAG-1 — macOS build, signing, and archive not performed

Windows cannot run Xcode. `flutter build ios`, `pod install`, `xcodebuild`, simulator/device runs, and `flutter build ipa` remain unverified. Must be run on macOS (see the macOS verification plan).

### FLAG-2 — Apple Developer account, team, and App ID availability unverified

No `DEVELOPMENT_TEAM` appears in `project.pbxproj`; `CODE_SIGN_STYLE = Automatic` exists only on RunnerTests (`:383`, `:400`, `:415`). Whether `com.mostafasayed.quranyahdi` is available/registered under the owner’s team cannot be checked without the Apple account.

### FLAG-3 — Device-only behavior

Notification authorization/foreground/cold-start, background audio + lock-screen controls, interruption/headset handling, location denial/`deniedForever`, magnetometer presence/calibration, download suspension when backgrounded, and RTL/text-scale rendering require a physical iPhone/iPad. Static code paths look coherent but are not proof.

### FLAG-4 — External policy items

UIScene adoption for the iOS 26 SDK, required-reason API enforcement, export-compliance exemption, and any App Store review policy claims are marked `POLICY (verify against current Apple guidance)`. The icon-alpha rejection is locally sourced (`flutter_launcher_icons/lib/ios.dart:129`) and is therefore a P0, not a FLAG.

### FLAG-5 — Runtime network/ATS behavior

Static evidence shows HTTPS-only endpoints (`reciter_repository.dart:63-71`; `library_catalog.dart:17`, `:79`) and no ATS exception keys in `Info.plist`. Actual CDN/API responses, redirects, TLS versions, and streaming behavior were not exercised (no network per scope).

### FLAG-6 — SQLite native-asset bundling on iOS

Static evidence: `sqlite3 3.7.1` uses Dart hooks (`sqlite3-3.7.1/doc/hook.md:5-7`), bundles precompiled iOS `arm64` and simulator binaries (`lib/src/hook/assets.dart:199-200`; `lib/src/hook/asset_hashes.dart` lists `libsqlite3.arm64.ios.dylib`), and Flutter 3.47.5 enables native assets by default on stable (`flutter_tools/lib/src/features.dart:205-212`). The actual dylib packaging/link/codesign on an iOS build must be verified on a Mac (`flutter build ios` + inspect the `.app`).

### FLAG-7 — iCloud backup behavior

The absence of `NSURLIsExcludedFromBackupKey` is proven statically; whether the backup size is acceptable and whether App Review raises it cannot be measured without a device/Apple account.

## Area checklists (A–N)

### A. Xcode project configuration

- **Deployment targets:** GAP — `project.pbxproj:349`, `:475`, `:526` = 12.0; `AppFrameworkInfo.plist:23-24` = 12.0; installed Flutter template = 15.0 (`templates/app/ios.tmpl/Runner.xcodeproj/project.pbxproj.tmpl:383`, `:513`, `:565`). See P1-4.
- **Bundle identifiers (Runner + RunnerTests):** GAP — `project.pbxproj:371`, `:550`, `:572` = `com.example.quranApp`; `:387`, `:404`, `:419` = `com.example.quranApp.RunnerTests`; intended id at `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md:71`. See P1-5.
- **Swift version:** PASS — `SWIFT_VERSION = 5.0` at `project.pbxproj:374`, `:391`, `:406`, `:421`, `:554`, `:575`; matches template.
- **Signing style/team:** FLAG — `CODE_SIGN_STYLE = Automatic` only on RunnerTests (`:383`, `:400`, `:415`); no `DEVELOPMENT_TEAM` anywhere in the project; Runner has no `CODE_SIGN_STYLE`. See FLAG-2.
- **`FLUTTER_BUILD_NAME/NUMBER` wiring:** PASS — `ios/Flutter/Generated.xcconfig:8-9` (`1.0.0`, `1`); `Info.plist:19-24` uses `$(FLUTTER_BUILD_NAME)`/`$(FLUTTER_BUILD_NUMBER)`; runner configs set `CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)"` (`project.pbxproj:364`, `:543`, `:565`).
- **Orientations:** PASS — `Info.plist:31-43` lists portrait/landscape for iPhone and all four for iPad.
- **Launch storyboard:** PASS — `Info.plist:27-28` (`LaunchScreen`), file present at `ios/Runner/Base.lproj/LaunchScreen.storyboard`.
- **Scheme:** PASS — `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme:1-98`; build/test/launch/profile/archive actions present; RunnerTests wired at `:39-51`.
- **UIScene lifecycle:** GAP — no `UIApplicationSceneManifest`, no `SceneDelegate.swift`; template has both (`Info.plist.tmpl:29-50`; `SceneDelegate.swift` 4 lines). See P1-6.
- **Asset-catalog setting:** GAP — `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon` at `:430`, `:487`. See P2-8.

### B. Info.plist & platform permissions

- **Display name / `CFBundleName`:** GAP — `Info.plist:7-8` = “Quran App”; `:15-16` = `quran_app`; Android label is Arabic (`AndroidManifest.xml:11`). See P2-1.
- **Development region/localizations:** GAP — `project.pbxproj:186` developmentRegion `en`, `:188-191` knownRegions only `en`, `Base`; no `CFBundleLocalizations`. See P2-2.
- **`UIBackgroundModes` (audio):** PASS — `Info.plist:48-51` contains `audio`.
- **`NSLocationWhenInUseUsageDescription`:** PASS (wording accurate) with localization gap — `Info.plist:46-47` Arabic string: “يُستخدم موقعك لاختيار أقرب مدينة لحساب مواقيت الصلاة، على جهازك فقط.”; English version missing (P2-2).
- **Notification keys:** PASS — no extra Info.plist keys are required by `flutter_local_notifications`; the delegate is the required setup (P1-3).
- **ATS:** PASS — no `NSAppTransportSecurity`/exception keys in `Info.plist`; all endpoints are HTTPS (`reciter_repository.dart:63-71`; `library_catalog.dart:17`, `:79`).
- **`ITSAppUsesNonExemptEncryption`:** GAP — key absent. See P2-4.
- **`InfoPlist.strings` (ar/en):** GAP — neither `ar.lproj` nor `en.lproj` exists in `ios/`. See P2-2.
- **Plugin-required keys:** PASS — `geolocator` requires `NSLocationWhenInUseUsageDescription` (present); `flutter_local_notifications`/`just_audio`/`sensors_plus`/`path_provider` require no additional Info.plist keys on iOS.

### C. Flutter/plugin minimum-OS compatibility

- **Flutter 3.47.5 requirement:** GAP — template and migration target 15.0 (`project.pbxproj.tmpl:383` etc.; `ios_deployment_target_migration.dart:88-118`), project is 12.0. See P1-4.
- **`flutter_local_notifications 22.3.2`:** GAP at current project target — podspec `:19` = 13.0; Package.swift `:9` = iOS 13.0.
- **`sensors_plus 7.1.1`:** GAP at current project target — podspec `:19` = 13.0.
- **`just_audio 0.10.6`:** PASS under 15.0 — `darwin/just_audio.podspec:19` = 12.0.
- **`audio_session 0.2.4`:** PASS — `ios/audio_session.podspec:19` = 12.0.
- **`audio_service 0.18.19`:** PASS — `darwin/audio_service.podspec:19` = 12.0.
- **`just_audio_background 0.0.1-beta.17`:** PASS — its `ios/just_audio_web.podspec:5`, `:19` is a no-op fake (`s.name = 'just_audio_web'`, 8.0); the real native code is `audio_service`.
- **`geolocator 14.0.1` / `geolocator_apple 2.3.15`:** PASS — `darwin/geolocator_apple.podspec:22` = 11.0.
- **`path_provider 2.1.6` / `path_provider_foundation 2.6.0`:** PASS — implementation is pure Dart FFI (`pubspec.yaml:14-18`, `dartPluginClass`), no podspec; `objective_c 9.6.2` builds for iOS via hooks (`hook/build.dart:176-231`).
- **`drift 2.35.2` / `sqlite3 3.7.1`:** PASS static — drift depends on `sqlite3 ^3.4.0` (`drift-2.35.2/pubspec.yaml:25`; `lib/native.dart:3-17`); sqlite3 uses hooks and bundles iOS binaries (`doc/hook.md:5-7`; `lib/src/hook/assets.dart:199-200`). Actual bundle is FLAG-6.
- **`dio 5.11.1` / `timezone 0.11.2`:** PASS — pure Dart, no native iOS minimum.
- **Locked versions:** `pubspec.lock:376` (flutter_local_notifications 22.3.2), `:647` (just_audio 0.10.6), `:655` (just_audio_background 0.0.1-beta.17), `:75` (audio_service 0.18.19), `:99` (audio_session 0.2.4), `:471` (geolocator_apple 2.3.15), `:951` (sensors_plus 7.1.1), `:815` (path_provider_foundation 2.6.0), `:291` (drift 2.35.2), `:1044` (sqlite3 3.7.1), `:275` (dio 5.11.1), `:1116` (timezone 0.11.2), `:775` (objective_c 9.6.2).

### D. Notifications (functional parity)

- **Darwin init settings:** GAP — only Android settings passed (`notifications_binding.dart:55-58`); plugin throws when `settings.iOS == null` (`flutter_local_notifications_plugin.dart:142-147`); catch leaves `_ready=false` (`notifications_binding.dart:71-73`). See P1-1.
- **Permission request path (boot grace + settings toggle):** GAP — Android-only (`notifications_binding.dart:89-99`, `:109-117`); no `IOSFlutterLocalNotificationsPlugin` in `lib/`; iOS permission API exists at `platform_flutter_local_notifications.dart:759-798`. See P1-2.
- **Darwin notification details:** GAP — `_details` contains only `android:` (`notifications_binding.dart:61-69`); iOS scheduling passes `notificationDetails.iOS == null` (`flutter_local_notifications_plugin.dart:447-459`; iOS impl `:818-830` uses `?? {}`). Fix under P1-1.
- **`zonedSchedule` iOS behavior:** PASS static — the binding maps fire instants as `TZDateTime.from(fireAt.toUtc(), tz.UTC)` (`notifications_binding.dart:137`); the plugin serializes `timeZoneName` + ISO date (`tz_datetime_mapper.dart:19-27`) and the iOS implementation builds the calendar trigger in that timezone (`FlutterLocalNotificationsPlugin.m:872-886`). This correctly reproduces the absolute instant on iOS as well as Android.
- **Foreground presentation:** GAP — no `UNUserNotificationCenter` delegate in AppDelegate (`AppDelegate.swift:4-12`); plugin README requires it (`README.md:473-482`); plugin’s `willPresentNotification` at `FlutterLocalNotificationsPlugin.m:1033-1065`. See P1-3.
- **AppDelegate delegate:** GAP — same as above (P1-3).
- **Cold-start `getNotificationAppLaunchDetails`:** PASS for v1 home landing, GAP for deep routing — no call in `lib/`; plugin documents it (`README.md:755`, `:1130`); cold start lands on home by default. See P2-9.
- **Tap→home (running):** PASS — `main.dart:36-38` wires `onTap` to `AppRouter.router.go('/home')`; binding fires it at `notifications_binding.dart:79-81`.
- **Tap→home (terminated):** PASS for v1 — app starts at home; no payload/deep link exists to lose. See P2-9 for future routing.
- **Timezone mapping:** PASS — UTC `TZDateTime` mapping (`notifications_binding.dart:137`) + plugin iOS timezone handling (`FlutterLocalNotificationsPlugin.m:872-886`); no `flutter_timezone` dependency is needed for absolute instants.
- **Exact-alarm settings (Android-only):** PASS — the binding selects `exactAllowWhileIdle`/`inexactAllowWhileIdle` only for Android (`notifications_binding.dart:125-130`); iOS ignores `androidScheduleMode` by design (`flutter_local_notifications_plugin.dart:447-459`).
- **Cancellation/reschedule on city change:** PASS — `prayer_times_cubit.dart:76-79` persists then reloads; `:59` calls `_scheduleReminders()`; `:64-74` calls the shared guarded `scheduleReminders`; `scheduleAll` does `cancelAll()` first (`notifications_binding.dart:131`).
- **Scheduling scope (v1):** PASS — next prayer ahead today + daily azkar; missed-while-dead reminders accepted (`reminder_planner.dart:31-73`).

### E. Audio & background execution

- **`UIBackgroundModes audio`:** PASS — `Info.plist:48-51`.
- **just_audio_background / audio_service iOS requirements:** PASS — README’s only iOS requirement is `UIBackgroundModes` audio (`just_audio_background-0.0.1-beta.17/README.md:98-107`); `audio_service` podspec targets iOS 12.0 (`darwin/audio_service.podspec:19`).
- **Audio session category:** PASS static — no explicit `AudioSession` override; just_audio’s documented default is the music-player session (`just_audio-0.10.6/README.md:473-482`). Device behavior is FLAG-3.
- **Now Playing / lock-screen metadata:** PASS static — every source gets a `MediaItem` tag (`just_audio_playback_service.dart:29-51`), which is how `just_audio_background` supplies Now Playing/remote controls.
- **Headset/interruption handling:** FLAG — delegated to `audio_service`/`audio_session`; no app-level code; device verification required (FLAG-3).
- **Background download limits (dio vs URLSession):** PASS/N-A — downloads stream in the Dart isolate with dio (`audio_downloader.dart:27-31`, `:102-126`; `pack_downloader.dart:41-45`, `:176-226`); there is no iOS background-URLSession claim and no Android foreground download service either. Downloads are foreground-only on both platforms.
- **Stop/cleanup semantics:** PASS — `stopAndReset` stops the service and unbinds streams (`playback_cubit.dart:131-140`), `close()` unbinds (`:169-173`); `_deleteIfInsideAudioRoot` deletes only under the audio root (`audio_downloader.dart:174-185`).
- **Init-failure guard:** PASS (disclosed) — `BackgroundInitGuard.attempt` never rethrows (`background_init_guard.dart:28-36`); a failed background init degrades to foreground playback rather than crashing boot.

### F. Location

- **Usage-description presence/accuracy/localization:** PASS for presence/accuracy — `Info.plist:46-47` is accurate and on-device-only. Localization is a GAP (P2-2).
- **geolocator iOS setup:** PASS — only `NSLocationWhenInUseUsageDescription` is required; present. Podspec targets iOS 11.0 (`geolocator_apple-2.3.15/darwin/geolocator_apple.podspec:22`); no background-location keys are used.
- **Denial/fallback flow:** PASS — `LocationService.currentPosition` collapses all failures to `null` (`location_service.dart:26-43`); `CityPickerCubit.locateNearest` returns `null` and keeps the manual picker (`city_picker_cubit.dart:41-66`); the neutral hint string exists (`app_ar.arb:1` `locationUnavailable`, `app_en.arb:1`).
- **No background location claims:** PASS — `UIBackgroundModes` contains only `audio` (`Info.plist:48-51`); Android manifest requests only coarse/fine (`AndroidManifest.xml:7-8`).

### G. Sensors/qibla

- **sensors_plus iOS support:** PASS — podspec `:19` = iOS 13.0; Swift implementation present.
- **Motion permission requirements:** PASS static — the app only consumes `magnetometerEventStream()` (`heading_service.dart:38-39`); CoreMotion magnetometer does not use `NSMotionUsageDescription` (that key is for motion activity/fitness). **POLICY (verify against current Apple guidance)** if Apple changes sensor permission requirements.
- **Graceful null/absence path:** PASS — `HeadingService.headingStream` catches construction errors and returns `null` (`heading_service.dart:30-36`); `QiblaCubit` simply skips binding when null (`qibla_cubit.dart:49-61`); stream errors are logged, not thrown (`:52-60`).
- **Device behavior:** FLAG-3 — no magnetometer in the simulator; live dial/calibration must be checked on hardware.

### H. Storage, DB, files

- **drift/sqlite3 iOS packaging:** PASS static — `drift 2.35.2` uses `package:sqlite3` (`drift-2.35.2/lib/native.dart:3-17`); `sqlite3 3.7.1` bundles precompiled iOS `arm64`/simulator binaries via hooks (`doc/hook.md:5-7`; `lib/src/hook/assets.dart:199-200`; `lib/src/hook/asset_hashes.dart` has `libsqlite3.arm64.ios.dylib`); Flutter 3.47.5 enables native assets by default (`features.dart:205-212`). FLAG-6 for the actual bundle/link.
- **Application Support path:** PASS — `getApplicationSupportDirectory()` is used for DB (`connection.dart:25-27`), audio (`bootstrap.dart:21-24`), and library (`bootstrap.dart:26-29`).
- **Bundled DB copy:** PASS — `assets/db/quran.sqlite` is 3,182,592 bytes; `copyDbAssetIfAbsent` copies it to `<Application Support>/quran_yahdi.sqlite` and opens `NativeDatabase.createInBackground` (`connection.dart:13-33`).
- **Audio/pack file locations:** PASS — `<root>/audio/<reciterRowId>/<surah>.mp3` (`audio_downloader.dart:59-66`), `<root>/library/<packId>.json` (`pack_downloader.dart:133-145`).
- **iCloud backup exposure:** GAP — Application Support is backed up by default; no `NSURLIsExcludedFromBackupKey` anywhere; audio/pack files are large. See P2-5.
- **File-protection/backup-exclusion options:** GAP — no data-protection class or backup-exclusion code exists; see P2-5.
- **Path-containment defenses portability:** PASS — both downloaders normalize and constrain deletes (`audio_downloader.dart:174-185`) or validate pack ids before composing paths (`pack_downloader.dart:128-145`); `package:path` is platform-aware, and iOS uses POSIX paths.
- **Actual packaging:** FLAG-6.

### I. Network/ATS

- **HTTPS-only endpoints:** PASS — reciters API is `https://mp3quran.net/...` (`reciter_repository.dart:71`); parsed audio servers must be HTTPS and `mp3quran.net`/subdomains (`:63-69`); library catalog rejects non-HTTPS URLs (`library_catalog.dart:17`, `:79`; catalog URLs `assets/data/library_catalog.json:1` are all `https://cdn.jsdelivr.net/...`).
- **ATS defaults:** PASS — no `NSAppTransportSecurity` exceptions in `Info.plist`; ATS defaults allow HTTPS and block cleartext.
- **dio timeouts/stream caps:** PASS — connect 15 s / receive 2 min (`audio_downloader.dart:27-31`; `pack_downloader.dart:41-45`); audio cap is 2× content-length + 64 KiB with a 64 MiB ceiling (`audio_downloader.dart:45-50`, `:115-117`); pack cap is 2× expected + 64 KiB (`pack_downloader.dart:117-119`, `:183-186`).
- **No cleartext exceptions needed:** PASS — no HTTP endpoints or ATS exceptions found.
- **Runtime:** FLAG-5.

### J. Assets & branding

- **AppIcon set completeness (+1024 marketing):** PASS on completeness — `Contents.json` covers iPhone/iPad sizes and `ios-marketing` 1024 (`:112-114`); 21 PNGs present.
- **Marketing icon alpha:** GAP (P0) — 1024 PNG is RGBA with `minAlpha=0`; see P0-1.
- **Launch screen content (brand vs default):** PASS — `LaunchScreen.storyboard:19-20` uses `LaunchBackground` (beige `#F1EAD7`, measured) + `LaunchImage` (orange app icon, measured center ARGB(255,255,179,15)).
- **Splash config (`flutter_native_splash` ios:true):** PASS — `pubspec.yaml:53-57` sets `color: "#f1ead7"`, `image: "assets/icons/app_icon_2.png"`, `android: true`, `ios: true`; generated `LaunchBackground` matches the color.
- **Bundled fonts (Cairo/HafsSmart/me_quran):** PASS — `pubspec.yaml:70-82`; files present under `assets/fonts/` (Cairo-Regular 164,492 B; Cairo-Bold 164,632 B; HafsSmart_08 301,184 B; me_quran 459,976 B).
- **Display name consistency:** GAP — see P2-1.
- **Dark-mode launch background:** GAP — single beige asset and white storyboard view background; see P2-7.

### K. Localization/RTL

- **AR/EN ARB coverage:** PASS — `app_ar.arb` 118 keys, `app_en.arb` 118 keys, zero missing either direction; both define `appName`, `reminderAzkar`, `reminderNextPrayer`
- **iOS app-language metadata:** GAP — no `CFBundleLocalizations`; `knownRegions` only `en`, `Base` (`project.pbxproj:186-191`); no `ar.lproj`/`en.lproj`. See P2-2.
- **Localized InfoPlist strings:** GAP — no `InfoPlist.strings` in `ios/`; the Arabic location purpose string is shown to all locales (`Info.plist:46-47`). See P2-2.
- **Arabic display name:** GAP — `CFBundleDisplayName` is “Quran App” (`Info.plist:7-8`); see P2-1/P2-2.
- **RTL surfaces already device-proven on Android:** PASS static for Flutter — app locale is `ar` (`app.dart:18`), supported locales include `en` (`:19`), and Flutter drives `Directionality`; iOS uses the same Dart UI. Device verification is FLAG-3.
- **Reminder text locale:** GAP (P2-10) — `reminder_scheduling.dart:28` hardcodes `Locale('ar')`.

### L. Privacy/compliance

- **`PrivacyInfo.xcprivacy` (app and third-party):** GAP — no app manifest; bundled manifests exist only for flutter_local_notifications, geolocator_apple, and sensors_plus; sensors_plus declares no API types while using `systemUptime`. See P2-3.
- **Required-reason API inventory (UserDefaults, file timestamps, disk space):** GAP/POLICY — flutter_local_notifications’ manifest declares `NSPrivacyAccessedAPICategoryUserDefaults`/`CA92.1`; sensors_plus’s manifest is empty despite `ProcessInfo.processInfo.systemUptime` (`FPPStreamHandlerPlus.swift:18`); SQLite/file-timestamp exposure must be confirmed. See P2-3.
- **Data collection claims vs `PRIVACY.md`:** PASS — the policy says no personal data/analytics/ads and on-device processing (`PRIVACY.md:5`, `:9-13`, `:19-22`, `:26-35`); `pubspec.yaml:8-33` lists no analytics/ad/tracking SDKs; no ATT framework is referenced in `lib/`.
- **Export-compliance key:** GAP — `ITSAppUsesNonExemptEncryption` absent; see P2-4.
- **ATT (not used — prove it):** PASS — no `AppTrackingTransparency`/`NSUserTrackingUsageDescription` or ad/analytics dependency exists in `pubspec.yaml` or `lib/`; all network hosts are content/media/CDN endpoints (`reciter_repository.dart:63-71`; `library_catalog.dart:17`).
- **Permission strings consistency:** PASS — only location needs a purpose string and it is present and accurate (`Info.plist:46-47`); localization gap is P2-2.

### M. Build/CI/verification path

- **Missing macOS CI:** GAP — `ci.yml:7-44` has only Ubuntu jobs. See P1-7.
- **Exact commands for a Mac:** PASS (plan below) — `flutter doctor -v`, `flutter pub get`, `flutter gen-l10n`, `dart run build_runner build --delete-conflicting-outputs`, `cd ios && pod install`, `flutter build ios --release --no-codesign`, `flutter build ipa`, `xcodebuild ...`.
- **Podfile/Podfile.lock:** GAP — absent; Flutter auto-generates the Podfile (`cocoapods.dart:251-267`). See P2-6.
- **Manual test matrix:** PASS (plan below).
- **Signing/archive:** FLAG-1/FLAG-2 — requires macOS + Apple team.

### N. Android→iOS parity matrix

See the dedicated matrix below.

## Android→iOS parity matrix (N)

| Capability | Android evidence | iOS evidence | Status |
|---|---|---|---|
| App id | `com.mostafasayed.quranyahdi` (`android/app/build.gradle:36`) | `com.example.quranApp` (`project.pbxproj:371`, `:550`, `:572`) | **GAP P1-5** |
| App display name | Arabic `قرآن يَهدي` (`AndroidManifest.xml:11`) | “Quran App” (`Info.plist:7-8`) | **GAP P2-1** |
| Backup disabled | `android:allowBackup="false"` (`AndroidManifest.xml:14`) | No backup exclusion; Application Support is iCloud-backed | **GAP P2-5** |
| Media notification / background audio | `AudioService` + `MediaButtonReceiver` (`AndroidManifest.xml:37-53`); `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (`:6`) | `UIBackgroundModes audio` (`Info.plist:48-51`); `MediaItem` tags (`just_audio_playback_service.dart:29-51`); `audio_service` podspec 12.0 | **PASS** (device FLAG-3) |
| Exact alarms | `SCHEDULE_EXACT_ALARM` (`AndroidManifest.xml:9`); `canScheduleExactNotifications` (`notifications_binding.dart:125-130`) | No exact-alarm concept; `UNCalendarNotificationTrigger` (`FlutterLocalNotificationsPlugin.m:872-934`) | **PASS (N/A)** |
| Notification permission grace | Android 13 `POST_NOTIFICATIONS` via `requestNotificationsPermission` (`notifications_binding.dart:99`, `:112`) | No iOS permission request (`notifications_binding.dart:109-117`); API exists at `platform_flutter_local_notifications.dart:759-798` | **GAP P1-2** |
| Notification init | `AndroidInitializationSettings` (`notifications_binding.dart:55-58`) | Missing `DarwinInitializationSettings`; plugin throws (`flutter_local_notifications_plugin.dart:142-147`) | **GAP P1-1** |
| Foreground notification presentation | Android notification channel (`notifications_binding.dart:61-69`) | No `UNUserNotificationCenter` delegate (`AppDelegate.swift:4-12`; README `:473-482`) | **GAP P1-3** |
| Reminders tap routing (running) | `onTap → /home` (`main.dart:36-38`) | Same Dart callback (platform-neutral); after init fix | **PASS** |
| Reminders tap routing (terminated) | No `getNotificationAppLaunchDetails`; app starts home | No `getNotificationAppLaunchDetails`; app starts home | **PASS for v1** (P2-9 for future deep links) |
| Background downloads | dio stream in Dart; no foreground download service | dio stream in Dart; no background URLSession | **PASS/N-A** (foreground-only both) |
| App icon | Android launcher icons generated (`pubspec.yaml:35-38`) | Complete set but 1024 has alpha (`Contents.json:112-114`; measured `minAlpha=0`) | **GAP P0-1** |
| Splash | `flutter_native_splash` android true (`pubspec.yaml:56`) | `flutter_native_splash` ios true (`:57`); beige background + icon (`LaunchScreen.storyboard:19-20`, `:22`) | **PASS** (dark variant P2-7) |
| Location permission | Coarse/fine in manifest (`AndroidManifest.xml:7-8`) | `NSLocationWhenInUseUsageDescription` (`Info.plist:46-47`) | **PASS** (localization P2-2) |
| Qibla sensors | sensors_plus Android implementation | sensors_plus iOS 13.0 (`sensors_plus.podspec:19`); CoreMotion magnetometer | **PASS** (device FLAG-3) |
| SQLite/DB | drift + sqlite3 native libs | drift + hooks-bundled iOS sqlite3 (`doc/hook.md:5-7`; `assets.dart:199-200`) | **PASS static** (FLAG-6) |

## Proposed remediation wave (ordered, pathspec-style; no code applied)

**IOS-1 — ship blockers**
1. `pubspec.yaml` — add `remove_alpha_ios: true` / `background_color_ios: "#f1ead7"` under `flutter_launcher_icons`; regenerate icons (`dart run flutter_launcher_icons`), touching only `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`.
2. `ios/Runner.xcodeproj/project.pbxproj` — 15.0 deployment target in 3 project configs; bundle ids in 6 occurrences; `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES` in Debug/Release.
3. `ios/Flutter/AppFrameworkInfo.plist` — remove `MinimumOSVersion` (or set 15.0).
4. `ios/Runner/Info.plist` — display name/localizations, export-compliance key, UIScene manifest (with the Swift file below).
5. `ios/Runner/AppDelegate.swift` — notification delegate assignment; UIScene registration pattern.
6. `ios/Runner/SceneDelegate.swift` — new file (UIScene migration).
7. `lib/features/notifications/data/notifications_binding.dart` — Darwin init/details, iOS permission + boot grace.
8. `ios/Runner/PrivacyInfo.xcprivacy` — new manifest (UserDefaults CA92.1; SystemBootTime 35F9.1; FileTimestamp C617.1 if confirmed).
9. `ios/Podfile`, `ios/Podfile.lock` — generated and committed on macOS.
10. `.github/workflows/ci.yml` — add `ios-build` macOS job.

**IOS-2 — polish**
11. `ios/Runner/ar.lproj/InfoPlist.strings`, `ios/Runner/en.lproj/InfoPlist.strings` — new localized strings.
12. `ios/Runner/Base.lproj/LaunchScreen.storyboard` — beige view background / dark appearance variant.
13. `lib/features/notifications/data/reminder_scheduling.dart` — use the active locale instead of `Locale('ar')`.
14. `lib/main.dart` — read `getNotificationAppLaunchDetails()` and route future payloads.
15. `PRIVACY.md` / `docs/store/` — document iCloud backup behavior or add backup exclusion.

**Commit shape:** one pathspec-scoped commit per numbered item or tightly coupled pair; no push until the owner’s GO.

## macOS verification plan (exact commands + manual test matrix)

**Commands (run on macOS with Xcode + CocoaPods + the owner’s Apple account):**
```bash
flutter doctor -v
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
cd ios && pod install && cd ..
flutter build ios --release --no-codesign
flutter build ipa --release --export-method app-store   # requires signing/team (FLAG-2)
open ios/Runner.xcworkspace
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO build
```
Then run on a simulator for layout/permission dialogs and on a physical device for notifications/audio/sensors.

**Manual test matrix:**
1. **First launch:** clean install; Arabic default; RTL layout; no crash; bundled DB opens (read a surah); settings persist after kill.
2. **Localization:** device language Arabic and English; app language list shows `ar`/`en` after P2-2; permission dialog text is localized; display name is Arabic (or localized).
3. **Notifications:** enable azkar reminder → permission prompt appears once; prayer reminder and azkar reminder fire with app foreground, background, and terminated; foreground banner appears; tap opens home; change city → pending reminders are replaced; change device timezone/DST → fire instant remains correct; disable → none fire.
4. **Audio:** stream and download a surah; background the app → playback continues; lock-screen controls and Now Playing metadata; headset pause/resume; phone-call interruption; stop clears the media notification.
5. **Location:** allow, deny, deny-forever, services off; manual city picker remains usable; no background location prompt.
6. **Qibla:** live heading on a physical device; static fallback in simulator/no-magnetometer.
7. **Downloads:** audio and a multi-MB pack (5.5 MB and 82 MB); progress; failure cleanup; delete; verify no files outside `<Application Support>/audio|library`.
8. **DB/storage:** first-run copy; app upgrade preserves DB; check backup size with iCloud backup enabled.
9. **Assets:** 1024 icon has no alpha; launch screen beige/icon; splash matches; dark mode.
10. **Store validation:** archive → validate in App Store Connect/TestFlight; confirm privacy manifest, export compliance, icon alpha, and UIScene all pass.

## Open questions / owner decisions

1. Is `com.mostafasayed.quranyahdi` registered/available under the owner’s Apple team? (P1-5, FLAG-2)
2. Is a 15.0 minimum acceptable (drops iOS 12–14), or is a lower floor required? The installed Flutter already requires 15.0. (P1-4)
3. Is UIScene migration required now for the iOS 26 SDK, and should it be done in this wave? (POLICY; P1-6)
4. Should audio/pack downloads be excluded from iCloud backup, or is backup exposure acceptable? (P2-5)
5. Confirm the app-level privacy-manifest reason codes, especially `sensors_plus`’s `systemUptime` and SQLite file timestamps. (POLICY; P2-3)
6. Notification permission UX: prompt at first boot (Darwin defaults) vs only when the user enables azkar? Recommendation: request only on opt-in (P1-2).
7. Is English UI intended on iOS? The app currently pins `Locale('ar')` (`app.dart:18`); notification text is also pinned to Arabic (P2-10).
8. Should `getNotificationAppLaunchDetails` be wired now for future per-type routing, or deferred with v1? (P2-9)

## Evidence index

### Repository files read

- `ios/Runner/Info.plist` (57 lines), `ios/Runner/AppDelegate.swift` (13 lines)
- `ios/Flutter/AppFrameworkInfo.plist` (26 lines), `ios/Flutter/Generated.xcconfig` (15 lines), `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig`
- `ios/Runner.xcodeproj/project.pbxproj` (all build settings, 600+ lines), `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` (98 lines)
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` (44 lines), `ios/Runner/Base.lproj/Main.storyboard`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` (2,519 B), all 21 `Icon-App-*.png` (dimensions/pixel format/alpha scanned)
- `ios/Runner/Assets.xcassets/LaunchBackground.imageset/*`, `LaunchImage.imageset/*` (dimensions/center pixel/alpha scanned)
- `ios/Runner/Runner-Bridging-Header.h`, `ios/RunnerTests/RunnerTests.swift`, `ios/Runner.xcworkspace/contents.xcworkspacedata`, `ios/.gitignore`
- Full `ios/` file inventory (no `Podfile`, `Podfile.lock`, `PrivacyInfo.xcprivacy`, `InfoPlist.strings`, `SceneDelegate.swift`, `ar.lproj`, `en.lproj`)
- `pubspec.yaml` (82 lines), `pubspec.lock` (versions at `:75`, `:99`, `:275`, `:291`, `:376`, `:471`, `:647`, `:655`, `:775`, `:815`, `:951`, `:1044`, `:1116`)
- `.github/workflows/ci.yml` (44 lines)
- `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml`
- `lib/main.dart`, `lib/app/app.dart`, `lib/app/bootstrap.dart`, `lib/app/router.dart`, `lib/core/di/injector.dart`, `lib/core/db/connection.dart`, `lib/core/l10n/platform_localizations.dart`
- `lib/features/notifications/data/notifications_binding.dart`, `reminder_planner.dart`, `reminder_scheduler.dart`, `reminder_scheduling.dart`, `reminder_settings.dart`
- `lib/features/settings/presentation/settings_cubit.dart`
- `lib/features/prayer/data/location_service.dart`, `city_repository.dart`, `prayer_time_service.dart`
- `lib/features/prayer/presentation/city_picker/city_picker_cubit.dart`, `prayer_times/prayer_times_cubit.dart`
- `lib/features/qibla/data/heading_service.dart`, `presentation/qibla_cubit.dart`
- `lib/features/recitation/data/audio_downloader.dart`, `reciter_repository.dart`
- `lib/features/recitation/playback/just_audio_playback_service.dart`, `playback_service.dart`, `background_init_guard.dart`
- `lib/features/recitation/presentation/playback/playback_cubit.dart`
- `lib/features/library/data/pack_downloader.dart`, `library_catalog.dart`
- `lib/l10n/app_ar.arb`, `lib/l10n/app_en.arb` (118/118 keys)
- `PRIVACY.md` (95 lines), `README.md`
- `docs/superpowers/specs/2026-10-15-quran-yahdi-rebuild-design.md` (`:70-71`, `:145`, `:166`)
- `assets/data/library_catalog.json`, `assets/db/quran.sqlite` (3,182,592 B), all `assets/fonts/*`, `assets/icons/*`

### Pub-cache docs/packages quoted

- `flutter_local_notifications-22.3.2` — `README.md:473-482,755,1130`; `lib/src/flutter_local_notifications_plugin.dart:142-147,409-494`; `lib/src/platform_flutter_local_notifications.dart:759-798,818-848`; `lib/src/tz_datetime_mapper.dart:19-27`; `ios/flutter_local_notifications.podspec:19`; `ios/flutter_local_notifications/Package.swift:9`; `ios/.../FlutterLocalNotificationsPlugin.m:410-502,658-700,711-760,872-934,1033-1065`; `Sources/.../PrivacyInfo.xcprivacy`
- `just_audio-0.10.6` — `README.md:473-482`; `darwin/just_audio.podspec:19`
- `just_audio_background-0.0.1-beta.17` — `README.md:98-107`; `ios/just_audio_web.podspec:5,19`
- `audio_service-0.18.19` — `darwin/audio_service.podspec:19`
- `audio_session-0.2.4` — `ios/audio_session.podspec:19`
- `geolocator_apple-2.3.15` — `darwin/geolocator_apple.podspec:22`; `Sources/.../PrivacyInfo.xcprivacy`
- `sensors_plus-7.1.1` — `ios/sensors_plus.podspec:19`; `Sources/.../FPPStreamHandlerPlus.swift:18`; `Sources/.../PrivacyInfo.xcprivacy` (14 lines, empty API types)
- `path_provider_foundation-2.6.0` — `pubspec.yaml:14-18`
- `objective_c-9.6.2` — `hook/build.dart:176-231`
- `drift-2.35.2` — `pubspec.yaml:25`; `lib/native.dart:3-17`
- `sqlite3-3.7.1` — `doc/hook.md:5-7`; `lib/src/hook/assets.dart:199-200`; `lib/src/hook/asset_hashes.dart`; `hook/build.dart:17-36`
- `flutter_launcher_icons-0.14.4` — `README.md:118`; `lib/ios.dart:129`; `lib/config/config.dart:35`

### Flutter SDK 3.47.5 files quoted

- `C:\src\flutter\packages\flutter_tools\templates\app\ios.tmpl\Runner.xcodeproj\project.pbxproj.tmpl:383,513,565` (15.0), `:344,468,526` (`YES`)
- `C:\src\flutter\packages\flutter_tools\templates\app\ios.tmpl\Runner\Info.plist.tmpl:9,29-50`
- `C:\src\flutter\packages\flutter_tools\templates\app\ios.tmpl\Runner\AppDelegate.swift:5-14`; `Runner\SceneDelegate.swift` (4 lines)
- `C:\src\flutter\packages\flutter_tools\templates\app\ios.tmpl\Flutter\AppFrameworkInfo.plist`
- `C:\src\flutter\packages\flutter_tools\templates\cocoapods\Podfile-ios:2`
- `C:\src\flutter\packages\flutter_tools\lib\src\ios\mac.dart:154-159`
- `C:\src\flutter\packages\flutter_tools\lib\src\ios\migrations\ios_deployment_target_migration.dart:70-118`
- `C:\src\flutter\packages\flutter_tools\lib\src\macos\cocoapods.dart:251-267,422-466`
- `C:\src\flutter\packages\flutter_tools\lib\src\features.dart:205-212`

### Measurements

- `Icon-App-1024x1024@1x.png`: 1024×1024, `Format32bppArgb`, sampled `minAlpha=0` (transparent pixels present).
- `LaunchBackground.imageset/background.png`: 1×1, center `ARGB(255,241,234,215)` = `#F1EAD7`.
- `LaunchImage.imageset/LaunchImage*.png`: 128/256/384 px, center `ARGB(255,255,179,15)`, sampled `minAlpha=0`.
- ARB parity: 118 AR keys, 118 EN keys, zero missing either direction.
- `assets/db/quran.sqlite`: 3,182,592 bytes.
