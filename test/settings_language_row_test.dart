import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/app_locale.dart';
import 'package:quran_yahdi/core/l10n/app_locale_controller.dart';
import 'package:quran_yahdi/features/settings/data/app_locale_repository.dart';
import 'package:quran_yahdi/features/settings/presentation/settings_screen.dart';

import 'support/settings_host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late AppLocaleController locale;

  setUp(() async {
    db = newTestDb();
    locale = AppLocaleController(AppLocaleRepository(db));
    await locale.load();
  });

  Future<void> pumpHost(WidgetTester tester) => pumpSettingsHost(
    tester,
    db: db,
    home: SettingsScreen(locale: locale),
  );

  testWidgets('the language row shows the current language', (tester) async {
    await pumpHost(tester);

    expect(find.text('اللغة'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
  });

  testWidgets('picking English switches and persists the language', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text('اللغة'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
    await tester.tap(find.text('الإنجليزية'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(locale.language, AppLanguage.english);
    expect(await AppLocaleRepository(db).load(), AppLanguage.english);
  });

  testWidgets('dismissing the dialog leaves the language alone', (
    tester,
  ) async {
    await pumpHost(tester);

    await tester.tap(find.text('اللغة'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(locale.language, AppLanguage.arabic);
  });

  testWidgets('without a controller the row stays out', (tester) async {
    await pumpSettingsHost(tester, db: db, home: const SettingsScreen());

    expect(find.text('اللغة'), findsNothing);
  });
}
