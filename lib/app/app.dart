import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/app_locale_controller.dart';
import '../core/theme/app_system_ui.dart';
import '../core/theme/app_theme.dart';
import '../features/library/data/pack_downloader.dart';
import '../l10n/app_localizations.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    // Release the decoded pack projections while backgrounded; the next read
    // re-decodes from disk. Registration is optional (tests boot without the
    // library), so a missing downloader is not an error.
    if (getIt.isRegistered<PackDownloader>()) {
      getIt<PackDownloader>().trimReadCache();
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
