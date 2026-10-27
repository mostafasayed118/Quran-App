import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
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
    );
  }
}
