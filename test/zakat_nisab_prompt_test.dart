import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_cubit.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  testWidgets(
      'cash without the active nisab price prompts; adding the price restores the verdict',
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

    expect(find.text('لا زكاة عليك'), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));

    // Field order: gold g, silver g, gold price, silver price, cash, debts.
    // Cash only — the active silver price (default mode) stays blank.
    await tester.enterText(fields.at(4), '1000');
    await tester.pumpAndSettle();

    expect(find.text('أدخل سعر الذهب/الفضة لحساب النصاب'), findsOneWidget);
    expect(find.text('الزكاة الواجبة'), findsNothing);
    expect(find.text('لا زكاة عليك'), findsNothing);
    expect(find.textContaining('٢٥'), findsNothing);

    // Supply the silver price → the normal verdict and amount appear.
    await tester.enterText(fields.at(3), '1');
    await tester.pumpAndSettle();

    expect(find.text('أدخل سعر الذهب/الفضة لحساب النصاب'), findsNothing);
    expect(find.text('الزكاة الواجبة'), findsOneWidget);
    expect(find.textContaining('٢٥'), findsOneWidget);
  });
}
