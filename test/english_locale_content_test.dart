import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/l10n/app_locale_controller.dart';
import 'package:quran_yahdi/core/l10n/app_localizations_digits.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

/// The English switch must change the CONTENT, not only the settings label and
/// the direction: every number the app formats for display has to follow the
/// locale, and the qibla dial's cardinal words are part of the copy.
void main() {
  final ar = lookupAppLocalizations(const Locale('ar'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('Arabic keeps the Arabic-Indic digits it always shipped', () {
    expect(ar.usesArabicIndicDigits, isTrue);
    expect(ar.number(7), '٧');
    expect(ar.digits('7'), '٧');
    expect(ar.digits('١٢٣'), '١٢٣');
  });

  test('English renders Western digits, converting an already-formatted value',
      () {
    expect(en.usesArabicIndicDigits, isFalse);
    expect(en.number(7), '7');
    expect(en.digits('١٢٣'), '123');
    expect(en.digits('1:23'), '1:23');
  });

  test('the qibla cardinals follow the catalogue', () {
    expect(ar.cardinalNorth, 'شمال');
    expect(ar.cardinalEast, 'شرق');
    expect(ar.cardinalSouth, 'جنوب');
    expect(ar.cardinalWest, 'غرب');
    expect(en.cardinalNorth, 'North');
    expect(en.cardinalEast, 'East');
    expect(en.cardinalSouth, 'South');
    expect(en.cardinalWest, 'West');
  });

  testWidgets('an English screen renders a formatted count in Western digits',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            final loc = AppLocalizations.of(context);
            return Text(loc.digits(loc.ayatCount(7)));
          },
        ),
      ),
    );

    expect(find.text('7 verses'), findsOneWidget);
    expect(find.text('٧ verses'), findsNothing);
  });
}
