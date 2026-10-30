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
  test('parseDecimalOrNull rejects malformed text and accepts Arabic digits',
      () {
    expect(parseDecimalOrNull('abc'), isNull);
    expect(parseDecimalOrNull('12.5.6'), isNull);
    expect(parseDecimalOrNull('-4'), isNull);
    expect(parseDecimalOrNull('١٢٫٥'), 12.5);
    expect(parseDecimalOrNull(''), 0);
  });

  testWidgets('invalid zakat input shows a field error and blocks the verdict',
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

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'abc');
    await tester.pumpAndSettle();

    expect(find.text('أدخل رقمًا صحيحًا'), findsOneWidget);
    expect(find.text('صحّح الحقول غير الصحيحة أولًا'), findsOneWidget);

    await tester.enterText(fields.first, '10');
    await tester.pumpAndSettle();

    expect(find.text('أدخل رقمًا صحيحًا'), findsNothing);
    expect(find.text('صحّح الحقول غير الصحيحة أولًا'), findsNothing);
  });
}
