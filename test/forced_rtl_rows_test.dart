import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_cubit.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_screen.dart';

import 'support/host.dart';

/// M6 (audit round 2): the month-pager rows used to force
/// `TextDirection.rtl`; they must now follow the ambient locale.
///
/// The assertion reads the RenderFlex's RESOLVED direction, not the widget's
/// nullable `textDirection` property: with the forced value the resolved
/// direction stays rtl in English, which is exactly what this test catches.
void main() {
  Future<void> pumpHijri(WidgetTester tester, Locale locale) async {
    final cubit = HijriCubit(service: HijriService());
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(
      BlocProvider<HijriCubit>.value(
        value: cubit,
        child: appShell(home: const HijriScreen(), locale: locale),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
  }

  TextDirection? monthRowDirection(WidgetTester tester) {
    final row = find
        .ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(Row),
        )
        .first;
    return tester.renderObject<RenderFlex>(row).textDirection;
  }

  testWidgets('the hijri month row follows the locale direction', (
    tester,
  ) async {
    await pumpHijri(tester, const Locale('ar'));
    expect(monthRowDirection(tester), TextDirection.rtl);

    await pumpHijri(tester, const Locale('en'));
    expect(monthRowDirection(tester), TextDirection.ltr);
  });
}
