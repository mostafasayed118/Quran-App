import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/domain/reminders.dart';
import '../core/l10n/app_locale_controller.dart';
import '../core/theme/app_system_ui.dart';
import '../core/theme/app_theme.dart';
import '../features/library/data/pack_downloader.dart';
import '../l10n/app_localizations.dart';
import 'bootstrap.dart';
import 'di/injector.dart';
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

  /// The day (UTC midnight epoch) and UTC offset the plan was last composed for.
  ///
  /// The plan is pinned to absolute instants, so a resume on a NEW day or in a
  /// new time zone must recompose it — otherwise yesterday's alarms are all
  /// in the past and the user gets silence.
  int _plannedDay = 0;
  int _plannedOffsetMinutes = 0;

  @override
  void initState() {
    super.initState();
    _markPlanFreshness();
    WidgetsBinding.instance.addObserver(this);
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

  /// Remembers the day/zone the current plan belongs to.
  void _markPlanFreshness() {
    final now = DateTime.now();
    _plannedDay =
        DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch;
    _plannedOffsetMinutes = now.timeZoneOffset.inMinutes;
  }

  /// Re-plans the reminders when the app comes back on a new day or in a new
  /// time zone (a phone that slept through midnight, a traveller).
  void _refreshRemindersIfStale() {
    final now = DateTime.now();
    final day =
        DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch;
    final offsetMinutes = now.timeZoneOffset.inMinutes;
    if (day == _plannedDay && offsetMinutes == _plannedOffsetMinutes) return;
    _markPlanFreshness();
    unawaited(_rescheduleGuarded('resume'));
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
      listenable: _locale,
      builder: (context, _) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
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
