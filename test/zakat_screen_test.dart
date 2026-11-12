import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/zakat/presentation/zakat_cubit.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_screen.dart';

import 'support/host.dart';

void main() {
  testWidgets('live inputs recompute; silver default; due amount appears',
      (tester) async {
    final cubit = ZakatCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<ZakatCubit>.value(
      value: cubit,
      child: appShell(home: const ZakatScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.text('لا زكاة عليك'), findsOneWidget);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));

    // Field order: gold g, silver g, gold price, silver price, cash, debts.
    await tester.enterText(fields.at(3), '1');
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    await tester.enterText(fields.at(4), '1000');
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.text('الزكاة الواجبة'), findsOneWidget);
    expect(find.text('المال الزكوي'), findsOneWidget);
    expect(find.textContaining('٢٥'), findsOneWidget);
  });

  testWidgets('scientific notation is refused by the amount fields',
      (tester) async {
    final cubit = ZakatCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<ZakatCubit>.value(
      value: cubit,
      child: appShell(home: const ZakatScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    final cash = find.byType(TextField).at(4);
    await tester.enterText(cash, '1e3');
    await tester.pump();

    final editable = tester.widget<EditableText>(
      find.descendant(of: cash, matching: find.byType(EditableText)),
    );
    expect(editable.controller.text, '13');
  });
}
