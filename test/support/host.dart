import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

/// Canonical MaterialApp shell shared by widget tests (locale ar/en, app
/// theme, l10n delegates). [wrap] applies around the MaterialApp so cubit
/// providers keep their original topology (wrap-outside vs inside [home]);
/// [textScale] non-null mirrors the text-scale probes' MediaQuery builder.
Widget appShell({
  required Widget home,
  Locale locale = const Locale('ar'),
  double? textScale,
  Widget Function(Widget app)? wrap,
}) {
  final app = MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.light,
    builder: textScale == null
        ? null
        : (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
    home: home,
  );
  return wrap == null ? app : wrap(app);
}

/// Pumps [appShell] and settles unless [settle] is false (bounded-pump sites
/// keep their own pump sequence).
Future<void> pumpAppHost(
  WidgetTester tester, {
  required Widget home,
  Locale locale = const Locale('ar'),
  double? textScale,
  Widget Function(Widget app)? wrap,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    appShell(home: home, locale: locale, textScale: textScale, wrap: wrap),
  );
  if (settle) await tester.pumpAndSettle();
}
