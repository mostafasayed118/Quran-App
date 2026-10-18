import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/zakat/data/zakat_calculator.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_cubit.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  group('parseDecimal accepts Arabic keyboard input', () {
    test('Arabic-Indic digits map to their western values', () {
      expect(parseDecimal('١٢٣'), 123);
      expect(parseDecimal('٢٥٠'), 250);
      expect(parseDecimal('٠'), 0);
    });

    test('Arabic decimal and thousands separators are honored', () {
      expect(parseDecimal('١٢٣٫٥'), 123.5);
      expect(parseDecimal('١٬٢٣٤٫٥'), 1234.5);
    });

    test('mixed western and Arabic-Indic digits still parse', () {
      expect(parseDecimal('1٢3'), 123);
    });
  });

  testWidgets('Arabic-Indic entry drives the live verdict and amount',
      (tester) async {
    final cubit = ZakatCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<ZakatCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: const ZakatScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'سعر جرام الفضة'), '١');
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'النقد المعروض'), '١٠٠٠');
    await tester.pumpAndSettle();

    expect(find.text('الزكاة الواجبة'), findsOneWidget);
    expect(find.textContaining('٢٥'), findsOneWidget);
  });
}
