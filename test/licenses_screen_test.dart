import 'dart:convert' show jsonDecode;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/settings/presentation/licenses_screen.dart';

import 'support/host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the HafsSmart EULA asset ships with the app', () async {
    final text =
        await rootBundle.loadString('assets/licenses/HafsSmart-EULA.txt');

    expect(text, contains('KFGQPC'));
    expect(text, contains('Free of Cost'));
  });

  test('the Tanzil attribution ships and states the basmala omission',
      () async {
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

  test('the stored text drops the repeated basmala the reader draws itself',
      () async {
    Future<Map<String, dynamic>> surah(int number) async => jsonDecode(
          await rootBundle.loadString('assets/quran/uthmani/$number.json'),
        ) as Map<String, dynamic>;

    final basmala = (await surah(1))['1'] as String;
    for (var number = 2; number <= 114; number++) {
      expect(
        (await surah(number))['1'],
        isNot(contains(basmala)),
        reason: 'surah $number stores the repeated basmala',
      );
    }
  });

  testWidgets('the screen lists the shipped content and font sources',
      (tester) async {
    await pumpAppHost(tester, home: const LicensesScreen());

    expect(find.text('التراخيص والمصادر'), findsOneWidget);
    expect(find.textContaining('QuranEnc.com'), findsOneWidget);
    expect(find.textContaining('بيكثال'), findsOneWidget);
    expect(find.textContaining('mp3quran.net'), findsOneWidget);
    expect(find.textContaining('KFGQPC'), findsOneWidget);
    expect(find.textContaining('تَنزيل'), findsOneWidget);
  });

  testWidgets('opening the HafsSmart terms shows the embedded EULA',
      (tester) async {
    await pumpAppHost(tester, home: const LicensesScreen());

    // The list grew with the Tanzil attribution tile, so the fonts section is
    // below the fold on the 800x600 test surface.
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
}
