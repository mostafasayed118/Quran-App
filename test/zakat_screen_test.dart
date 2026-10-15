import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_cubit.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  testWidgets('live inputs recompute; silver default; due amount appears',
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
    await tester.enterText(fields.at(3), '1');
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(4), '1000');
    await tester.pumpAndSettle();

    expect(find.text('الزكاة الواجبة'), findsOneWidget);
    expect(find.text('المال الزكوي'), findsOneWidget);
    expect(find.textContaining('٢٥'), findsOneWidget);
  });
}
