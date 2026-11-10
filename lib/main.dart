import 'dart:async';
import 'package:quran_yahdi/core/utils/app_log.dart';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:workmanager/workmanager.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/di/injector.dart';
import 'app/onboarding_gate.dart';
import 'app/reminder_background_task.dart';
import 'app/router.dart';
import 'app/version_gate.dart';
import 'core/domain/version_ack_store.dart';
import 'core/domain/version_policy.dart';
import 'core/domain/version_policy_source.dart';
import 'core/domain/adhan_player.dart';
import 'core/l10n/app_locale_controller.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/l10n/platform_localizations.dart';
import 'core/utils/app_routes.dart';
import 'core/utils/boot_fail_open.dart';
import 'core/utils/deep_links.dart';
import 'features/notifications/data/notifications_binding.dart';
import 'features/notifications/data/reminder_planner.dart'
    show azkarReminderPayload, prayerReminderPayload, wirdReminderPayload;
import 'features/notifications/data/reminder_settings.dart';
import 'features/recitation/data/reciter_repository.dart';
import 'features/recitation/playback/background_init_guard.dart';

/// F-D1 fail-open budgets: the two plugin inits may each take at most this
/// long — a plugin that overruns is abandoned and boot proceeds (the helper
/// logs the failure under `quran_yahdi/boot`).
///
/// The inits run BEHIND the first frame, so these are a backstop on a stuck
/// plugin, not the time the user spends on a blank splash.
const _bootAudioInitTimeout = Duration(milliseconds: 1500);
const _bootNotificationsInitTimeout = Duration(milliseconds: 1500);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(
    audioRootResolver: defaultAudioRootResolver,
    citiesLoader: defaultCitiesLoader,
    azkarLoader: defaultAzkarLoader,
    duasLoader: defaultDuasLoader,
    ruqyahLoader: defaultRuqyahLoader,
    asmaLoader: defaultAsmaLoader,
    libraryCatalogLoader: defaultLibraryCatalogLoader,
    libraryRootResolver: defaultLibraryRootResolver,
  );
  final loc = platformLocalizations();
  // Arm the first-run gate: constructing it attaches the persisted flag and
  // kicks the first read. The router consults the cache synchronously and
  // re-runs its redirect when the read lands, so the flow opens as soon as the
  // answer is known — and a launch target (reminder tap, deep link) is
  // remembered and restored after the flow.
  getIt<OnboardingGate>();
  // The version gate attaches behind the first frame: it needs the installed
  // version from PackageInfo. Fail-open — if this never lands, the gate never
  // blocks a route.
  unawaited(_attachVersionGate());
  // Same for the language: the stored choice is read behind the first frame
  // and the root rebuilds when it lands (Arabic until then).
  unawaited(getIt<AppLocaleController>().load());
  // Appearance follows the same pattern: system until the stored choice lands.
  unawaited(getIt<AppThemeController>().load());
  // The first frame never waits for a plugin: the audio and notifications
  // plugins initialize behind the running app, and the app tolerates a
  // not-yet-initialized notifications binding (every call is a no-op until
  // the plugin reports ready).
  runApp(const QuranYahdiApp());
  unawaited(_initPlugins('${loc.recitationsTitle} — ${loc.appName}'));
}

/// The plugin bootstrap, off the first-frame path.
///
/// The order is the pre-refactor one: the plugins initialize first, then the
/// boot-only side effects that need them (the POST_NOTIFICATIONS grace needs
/// a ready binding, the reminder schedule needs the scheduler).
Future<void> _initPlugins(String audioChannelName) async {
  await Future.wait<void>([
    failOpenBootInit(
      'JustAudioBackground.init',
      () => BackgroundInitGuard.attempt(
        () => JustAudioBackground.init(
          androidNotificationChannelId:
              'com.mostafasayed.quranyahdi.channel.audio',
          androidNotificationChannelName: audioChannelName,
          androidNotificationOngoing: true,
        ),
      ),
      timeout: _bootAudioInitTimeout,
    ),
    failOpenBootInit(
      'NotificationsBinding.init',
      () => getIt<NotificationsBinding>().init(
        onTap: () => AppRouter.router.go(AppRoutes.home),
        onTapPayload: (payload) =>
            AppRouter.router.go(reminderRouteFor(payload) ?? AppRoutes.home),
        // The notification's "play adhan" action. The media session supplies
        // the stop control, so this never needs to open the app.
        onPlayAdhan: (trackId) => getIt<AdhanPlayer>().play(trackId),
      ),
      timeout: _bootNotificationsInitTimeout,
    ),
  ]);
  unawaited(_requestBootNotificationGrace());
  unawaited(_openReminderLaunchTarget());
  unawaited(_playAdhanLaunchTarget());
  unawaited(_openDeepLinkLaunchTarget());
  _listenForDeepLinks();
  unawaited(runBootReminderSchedule());
  unawaited(_registerBackgroundReminders());
  unawaited(_warmReciterCatalog());
}

/// Registers the periodic background re-plan (WorkManager).
///
/// Behind the first frame and best-effort: a platform without WorkManager, a
/// test host or a refused registration must never affect boot. The schedule is
/// already applied by [runBootReminderSchedule]; this keeps the rolling window
/// fresh (and recovers the alarms right after a long boot) while the app stays
/// closed. Registration is idempotent — the platform keeps the existing task.
Future<void> _registerBackgroundReminders() async {
  try {
    await Workmanager().initialize(reminderTaskDispatcher);
    await Workmanager().registerPeriodicTask(
      reminderRefreshUniqueName,
      reminderRefreshTask,
      frequency: reminderRefreshFrequency,
      // The first run lands right after the task is first registered, so the
      // background path proves itself on a fresh install instead of waiting a
      // full period — and a device check does not have to sit for 30 minutes.
      initialDelay: const Duration(seconds: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } on Object catch (error, stackTrace) {
    appLog(
      'background reminder registration failed',
      name: 'quran_yahdi/boot',
      error: error.runtimeType,
      stackTrace: stackTrace,
    );
  }
}

/// First-run warm-up for the audio catalog.
///
/// The reader's play button resolves a reciter from the DB, which is empty
/// until the mp3quran catalog has been fetched once. Fetching here (behind the
/// first frame, never on the boot path) makes playback work before the user
/// ever opens the recitations screen. Fail-open: offline stays offline, and
/// the recitations screen keeps its own retry path.
Future<void> _warmReciterCatalog() async {
  try {
    await getIt<ReciterRepository>().ensureCatalog();
  } on Object catch (error, stackTrace) {
    appLog('reciter catalog warm-up failed',
        name: 'quran_yahdi/boot',
        error: error.runtimeType,
        stackTrace: stackTrace);
  }
}

/// Tap-target route for a reminder payload; null for unknown/absent payloads
/// (the caller falls back to `/home`). Warm taps and cold launches share it.
String? reminderRouteFor(String? payload) => switch (payload) {
      prayerReminderPayload => AppRoutes.prayerTimes,
      azkarReminderPayload => AppRoutes.azkar,
      wirdReminderPayload => AppRoutes.worship,
      _ => null,
    };

/// Cold-start routing: when the app was launched by tapping a reminder, land
/// on its own screen instead of home. Best-effort — a launch-details read
/// failure never breaks boot (W7b discipline).
Future<void> _openReminderLaunchTarget() async {
  try {
    final route =
        reminderRouteFor(await getIt<NotificationsBinding>().launchPayload());
    if (route == null) return;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => AppRouter.router.go(route));
  } on Object catch (error, stackTrace) {
    appLog('reminder launch routing failed',
        name: 'quran_yahdi/boot',
        error: error.runtimeType,
        stackTrace: stackTrace);
  }
}

/// Cold-start "play adhan" action: the app was launched by the notification's
/// action button, so start the adhan once the plugins are up. Best-effort — a
/// failure never breaks boot.
Future<void> _playAdhanLaunchTarget() async {
  try {
    final trackId = await getIt<NotificationsBinding>().launchAdhanActionId();
    if (trackId == null) return;
    await getIt<AdhanPlayer>().play(trackId);
  } on Object catch (error, stackTrace) {
    appLog('adhan launch target failed',
        name: 'quran_yahdi/boot',
        error: error.runtimeType,
        stackTrace: stackTrace);
  }
}

/// First-boot POST_NOTIFICATIONS grace (UX-FIX 2): run once after plugin
/// init, only for an azkar-reminders opt-in user with notifications off at
/// the OS level. Best-effort — a DB or plugin failure never breaks boot.
Future<void> _requestBootNotificationGrace() async {
  try {
    final azkarEnabled = await getIt<ReminderSettings>().azkarEnabled();
    await getIt<NotificationsBinding>()
        .requestBootPermission(azkarEnabled: azkarEnabled);
  } on Object catch (error, stackTrace) {
    appLog('boot notification grace failed',
        name: 'quran_yahdi/boot',
        error: error.runtimeType,
        stackTrace: stackTrace);
  }
}

/// Cold-start deep-link routing (P4-app): when the app was launched from a
/// https://quranyahdi.pages.dev content link, land on its mapped route.
/// Best-effort — a link read failure never breaks boot (W7b discipline).
Future<void> _openDeepLinkLaunchTarget() async {
  try {
    final uri = await AppLinks().getInitialLink();
    if (uri == null) return;
    final route = deepLinkRouteFor(uri);
    if (route == null) return;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => AppRouter.router.go(route));
  } on Object catch (error, stackTrace) {
    appLog('deep link launch routing failed',
        name: 'quran_yahdi/boot',
        error: error.runtimeType,
        stackTrace: stackTrace);
  }
}

/// Resolves the installed version and attaches the version gate.
///
/// When (and only when) the policy read reports "update recommended" — the
/// install is supported but behind the latest — and the user has not already
/// dismissed this recommendation, the optional-update prompt is pushed once
/// after the first frame settles. A mandatory policy never pushes: the
/// router redirects everything to `/update` on its own.
Future<void> _attachVersionGate() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final installed = AppVersion.parse('${info.version}+${info.buildNumber}') ??
        AppVersion.parse(info.version);
    final gate = getIt<VersionGate>();
    gate.attach(
      source: getIt<VersionPolicySource>(),
      ackStore: getIt<VersionAckStore>(),
      installed: installed ?? const AppVersion(1, 0, 0),
    );
    await gate.settled;
    if (!gate.shouldShowRecommendedPrompt) return;
    await WidgetsBinding.instance.endOfFrame;
    await AppRouter.router.push(AppRoutes.update);
  } on Object catch (error, stackTrace) {
    appLog(
      'version gate attach failed',
      name: 'quran_yahdi/version-gate',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Warm deep links: every link that arrives while the app runs maps through
/// the pure [deepLinkRouteFor] and navigates. Disclosed v1: the app-lifetime
/// listener is never disposed, and on platforms that replay the initial link
/// on the stream the second [AppRouter.router.go] to the same route is
/// idempotent.
void _listenForDeepLinks() {
  AppLinks().uriLinkStream.listen((uri) {
    final route = deepLinkRouteFor(uri);
    if (route != null) AppRouter.router.go(route);
  });
}
