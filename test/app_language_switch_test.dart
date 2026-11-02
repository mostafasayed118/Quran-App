import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/app_locale.dart';
import 'package:quran_yahdi/core/l10n/app_locale_controller.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _Source implements AppLocaleSource {
  _Source({this.language = AppLanguage.arabic});

  AppLanguage language;

  @override
  Future<AppLanguage> load() async => language;

  @override
  Future<void> save(AppLanguage value) async {
    language = value;
  }
}

/// The app root's contract: `locale` comes from the controller, the direction
/// follows the locale, and the shipped locales are advertised.
Widget _app(AppLocaleController controller) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        locale: controller.locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Column(
            children: [
              Text(AppLocalizations.of(context).settings),
              Text(Directionality.of(context).name),
            ],
          ),
        ),
      ),
    );

void main() {
  testWidgets('Arabic is the default: Arabic copy, right-to-left',
      (tester) async {
    final controller = AppLocaleController(_Source());
    await controller.load();

    await tester.pumpWidget(_app(controller));

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('rtl'), findsOneWidget);
  });

  testWidgets('switching to English flips the copy and the direction',
      (tester) async {
    final controller = AppLocaleController(_Source());
    await controller.load();
    await tester.pumpWidget(_app(controller));

    await controller.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('ltr'), findsOneWidget);
    expect(find.text('الإعدادات'), findsNothing);
  });

  testWidgets('a stored English preference starts left-to-right',
      (tester) async {
    final controller =
        AppLocaleController(_Source(language: AppLanguage.english));
    await controller.load();

    await tester.pumpWidget(_app(controller));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('ltr'), findsOneWidget);
  });
}
