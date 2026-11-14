import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../core/domain/prayer_name.dart';
import '../core/domain/reminder_diagnostics.dart';
import '../core/domain/reminders.dart';
import '../core/l10n/app_locale_controller.dart';
import '../core/theme/app_system_ui.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_theme_controller.dart';
import '../core/theme/prayer_skin_controller.dart';
import '../features/library/data/pack_downloader.dart';
import '../l10n/app_localizations.dart';
import 'bootstrap.dart';
import 'di/injector.dart';
import 'prayer_period_controller.dart';
import 'reminder_plan_freshness.dart';
import 'router.dart';
import 'splash_screen.dart';

/// The chrome theme for [shipped] under the prayer skin.
///
/// `fixed` (or a period that has not been computed yet) returns [shipped]
/// **unchanged** — the rollback path is the identity, not a rebuilt theme.
ThemeData chromeTheme({
  required ThemeData shipped,
  required bool followsPrayer,
  required PrayerName? period,
}) {
  if (!followsPrayer || period == null) return shipped;
  return AppTheme.forPrayer(period, shipped.brightness);
}

class QuranYahdiApp extends StatefulWidget {
  const QuranYahdiApp({super.key});

  @override
  State<QuranYahdiApp> createState() => _QuranYahdiAppState();
}

class _QuranYahdiAppState extends State<QuranYahdiApp>
    with WidgetsBindingObserver {
  /// The language switch (D1 v1.1): the settings row flips it and the root
  /// rebuilds, so `Directionality` follows (ar → RTL, en → LTR).
  late final AppLocaleController _locale = getIt<AppLocaleController>();

  /// The appearance switch: the settings row flips it and the root rebuilds
  /// `MaterialApp.themeMode` (system until the stored choice lands).
  late final AppThemeController _theme = getIt<AppThemeController>();

  /// The opt-in prayer skin. `fixed` until the stored choice lands.
  late final PrayerSkinController _skin = getIt<PrayerSkinController>();

  /// Which period it is, when the skin follows the prayer. No timer runs while
  /// the skin is `fixed`.
  late final PrayerPeriodController _period = getIt<PrayerPeriodController>();

  /// The day/zone the current plan belongs to, plus the last observed
  /// exact-alarm grant (a grant change alters the schedule MODE).
  final ReminderPlanFreshness _planFreshness = ReminderPlanFreshness();
  bool? _exactAlarmsAllowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The boundary timer only runs when the skin follows the prayer, so it is
    // started/stopped with the flag (and re-armed on a settings flip).
    _skin.addListener(_syncPrayerSkin);
    _syncPrayerSkin();
    // Establish the grant baseline so the first resume does not re-plan for
    // nothing; a change is what matters.
    unawaited(_syncAlarmGrant());
  }

  @override
  void dispose() {
    _skin.removeListener(_syncPrayerSkin);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Starts or stops the period source with the flag.
  void _syncPrayerSkin() {
    if (_skin.followsPrayer) {
      _period.start();
    } else {
      _period.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // Release the decoded pack projections while backgrounded; the next
        // read re-decodes from disk. Registration is optional (tests boot
        // without the library), so a missing downloader is not an error.
        if (getIt.isRegistered<PackDownloader>()) {
          getIt<PackDownloader>().trimReadCache();
        }
      case AppLifecycleState.resumed:
        _refreshRemindersIfStale();
        // The device may have slept across several boundaries (or the user
        // travelled): recompute instead of trusting the pending timer.
        if (_skin.followsPrayer) unawaited(_period.refresh());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Re-plans the reminders when the app comes back on a new day, in a new
  /// time zone (a phone that slept through midnight, a traveller), or after the
  /// exact-alarm permission changed.
  void _refreshRemindersIfStale() {
    final now = DateTime.now();
    if (_planFreshness.needsReplan(now)) {
      _planFreshness.mark(now);
      unawaited(_rescheduleGuarded('resume'));
    }
    unawaited(_syncAlarmGrant());
  }

  /// Re-plans when the OS exact-alarm grant changed.
  ///
  /// The grant does not change the PLAN, it changes how the platform stores it
  /// (exact vs inexact). The binding's fingerprint cannot see that, so without
  /// this a user who grants the permission from the system screen keeps the
  /// inexact alarms until some unrelated setting changes the plan.
  Future<void> _syncAlarmGrant() async {
    try {
      if (!getIt.isRegistered<ReminderDiagnostics>()) return;
      final allowed = await getIt<ReminderDiagnostics>().exactAlarmsAllowed();
      final previous = _exactAlarmsAllowed;
      _exactAlarmsAllowed = allowed;
      if (previous == null || previous == allowed) return;
      await _rescheduleGuarded('exact-alarm grant changed');
    } on Object catch (error, stackTrace) {
      appLog(
        'exact-alarm grant read failed',
        name: 'quran_yahdi/app',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
  }

  /// Best-effort: a failed re-plan must never break the running app; the next
  /// open or settings change retries.
  Future<void> _rescheduleGuarded(String reason) async {
    try {
      if (!getIt.isRegistered<ReminderRescheduler>()) return;
      await runBootReminderSchedule();
    } on Object catch (error, stackTrace) {
      appLog(
        'reminder re-plan on $reason failed',
        name: 'quran_yahdi/app',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // The skin and the period are read INSIDE the builder. A
      // ListenableBuilder re-runs only its builder, never the enclosing
      // `build`, so values captured out here would freeze at the last root
      // build — the period stays null and the palette never lands (found on a
      // device: the settings row said "follow" while the chrome stayed
      // shipped). `_period` is always in the merge because membership cannot
      // depend on a value read outside; the controller is stopped while fixed,
      // so it does not notify.
      listenable: Listenable.merge(<Listenable>[
        _locale,
        _theme,
        _skin,
        _period,
      ]),
      builder: (context, _) {
        final follows = _skin.followsPrayer;
        final period = follows ? _period.period : null;
        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          theme: chromeTheme(
            shipped: AppTheme.light,
            followsPrayer: follows,
            period: period,
          ),
          darkTheme: chromeTheme(
            shipped: AppTheme.dark,
            followsPrayer: follows,
            period: period,
          ),
          themeMode: _theme.themeMode,
          // MaterialApp already animates a theme change over this duration and
          // curve. A second `AnimatedTheme` in the builder chains two lerps: the
          // widget test showed the target arriving after ~900 ms instead of
          // 400 ms. One owner, one fade.
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeInOut,
          locale: _locale.locale,
          // Arabic stays the default (AppLanguage.arabic); English is opt-in
          // from the settings row, and the EN ARB is a full mirror of the AR
          // template.
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppSystemUi.overlayStyle(Theme.of(context).brightness),
            child: SplashScreen(child: child!),
          ),
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
