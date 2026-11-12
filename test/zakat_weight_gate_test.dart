import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/zakat/presentation/zakat_cubit.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_screen.dart';

import 'support/host.dart';

void main() {
  testWidgets('weight-only input asks for the price instead of "no zakat"',
      (tester) async {
    final cubit = ZakatCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<ZakatCubit>.value(
      value: cubit,
      child: appShell(home: const ZakatScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    await tester.enterText(find.widgetWithText(TextField, 'فضة (جرام)'), '٥٠٠');
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.text('أدخل سعر الذهب/الفضة لحساب النصاب'), findsOneWidget);
    expect(find.text('لا زكاة عليك'), findsNothing);
  });
}
