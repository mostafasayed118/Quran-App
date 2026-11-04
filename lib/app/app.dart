import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/domain/reminder_diagnostics.dart';
import '../core/domain/reminders.dart';
import '../core/l10n/app_locale_controller.dart';
import '../core/theme/app_theme_controller.dart';
import '../core/theme/app_system_ui.dart';
import '../core/theme/app_theme.dart';
import '../features/library/data/pack_downloader.dart';
import '../l10n/app_localizations.dart';
import 'bootstrap.dart';
import 'di/injector.dart';
import 'reminder_plan_freshness.dart';
import 'router.dart';

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

  /// The day/zone the current plan belongs to, plus the last observed
  /// exact-alarm grant (a grant change alters the schedule MODE).
  final ReminderPlanFreshness _planFreshness = ReminderPlanFreshness();
  bool? _exactAlarmsAllowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Establish the grant baseline so the first resume does not re-plan for
    // nothing; a change is what matters.
    unawaited(_syncAlarmGrant());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      dev.log(
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
      dev.log(
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
      listenable: Listenable.merge(<Listenable>[_locale, _theme]),
      builder: (context, _) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _theme.themeMode,
        locale: _locale.locale,
        // Arabic stays the default (AppLanguage.arabic); English is opt-in from
        // the settings row, and the EN ARB is a full mirror of the AR template.
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppSystemUi.overlayStyle(Theme.of(context).brightness),
          child: child!,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
