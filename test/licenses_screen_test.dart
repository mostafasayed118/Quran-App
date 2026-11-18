import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/settings/presentation/licenses_screen.dart';

import 'support/host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The adhan attribution tile lengthens the list; a default 800x600 surface
  // leaves the fonts section unmounted in a ListView.
  Future<void> pumpTallLicenses(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpAppHost(tester, home: const LicensesScreen());
  }

  test('the HafsSmart EULA asset ships with the app', () async {
    final text = await rootBundle.loadString(
      'assets/licenses/HafsSmart-EULA.txt',
    );

    expect(text, contains('KFGQPC'));
    expect(text, contains('Free of Cost'));
  });

  test('the Tanzil attribution ships and states the basmala omission', () async {
    final text = await rootBundle.loadString(
      'assets/licenses/tanzil-quran-uthmani.txt',
    );

    expect(text, contains('Tanzil Project'));
    expect(text, contains('tanzil.net'));
    // The stored copy is not verbatim, and the file has to say so: the terms it
    // quotes two paragraphs above forbid modification.
    expect(text, contains('basmala'));
    expect(text, contains('not a verbatim copy'));
  });

  testWidgets('the screen lists the shipped content and font sources', (
    tester,
  ) async {
    await pumpTallLicenses(tester);
    expect(find.text('التراخيص والمصادر'), findsOneWidget);
    expect(find.textContaining('QuranEnc.com'), findsOneWidget);
    expect(find.textContaining('بيكثال'), findsOneWidget);
    expect(find.textContaining('mp3quran.net'), findsOneWidget);
    expect(find.textContaining('KFGQPC'), findsOneWidget);
    expect(find.textContaining('تَنزيل'), findsOneWidget);
  });

  testWidgets('opening the HafsSmart terms shows the embedded EULA', (
    tester,
  ) async {
    await pumpTallLicenses(tester);

    // The attribution tiles lengthen the list; the tall surface keeps the
    // fonts section mounted for the tap.
    await tester.ensureVisible(find.text('عرض اتفاقية ترخيص خط Hafs Smart'));
    await tester.pump();
    await tester.tap(find.text('عرض اتفاقية ترخيص خط Hafs Smart'));
    await tester.pump();

    // The dialog loads the EULA through rootBundle (real asset I/O); let the
    // real event loop run, then rebuild. Bounded pumps: the loading spinner
    // never settles under pumpAndSettle.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(
      find.textContaining('ELECTRONIC END-USER LICENSE AGREEMENT'),
      findsOneWidget,
    );
    expect(find.textContaining('Free of Cost'), findsOneWidget);
  });

  testWidgets('320 dp at textScale 2.0 survives the licenses list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpAppHost(tester, textScale: 2.0, home: const LicensesScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('التراخيص والمصادر'), findsOneWidget);
  });
}
