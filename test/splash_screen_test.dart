import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/splash_screen.dart';
import 'package:quran_yahdi/core/l10n/app_locale_controller.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  testWidgets('overlay shows the brand, then dismisses itself', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SplashScreen(child: SizedBox(key: Key('routed-app'))),
      ),
    );

    // Brand is up on the very first frame; the routed app sits underneath.
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('قرآن يَهدي'), findsOneWidget);
    expect(find.text('القرآن الكريم بين يديك'), findsOneWidget);
    expect(find.byKey(const Key('routed-app')), findsOneWidget);

    // Still painted while inside the hold window.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Image), findsOneWidget);

    // Hold elapses, fade completes, overlay removes itself.
    await tester.pump(const Duration(milliseconds: 251));
    await tester.pump(SplashScreen.fade + const Duration(milliseconds: 40));
    expect(find.byType(Image), findsNothing);
    expect(find.text('قرآن يَهدي'), findsNothing);
    // The routed app survived the whole overlay lifecycle untouched.
    expect(find.byKey(const Key('routed-app')), findsOneWidget);
  });
}
