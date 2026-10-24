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

  testWidgets('the screen lists the shipped content and font sources',
      (tester) async {
    await pumpAppHost(tester, home: const LicensesScreen());

    expect(find.text('التراخيص والمصادر'), findsOneWidget);
    expect(find.textContaining('QuranEnc.com'), findsOneWidget);
    expect(find.textContaining('بيكثال'), findsOneWidget);
    expect(find.textContaining('mp3quran.net'), findsOneWidget);
    expect(find.textContaining('KFGQPC'), findsOneWidget);
  });

  testWidgets('opening the HafsSmart terms shows the embedded EULA',
      (tester) async {
    await pumpAppHost(tester, home: const LicensesScreen());

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
