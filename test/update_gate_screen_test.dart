import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/update/presentation/update_gate_screen.dart';

import 'support/host.dart';

Widget _pump({required bool mandatory}) => appShell(
        home: UpdateGateScreen(
      mandatory: mandatory,
      onOpenStore: () async => true,
      onLater: () async {},
    ));

void main() {
  testWidgets('mandatory mode hides the back affordance and the Later button',
      (tester) async {
    await tester.pumpWidget(_pump(mandatory: true));

    expect(find.text('تحديث مطلوب'), findsWidgets);
    expect(find.text('حدّث الآن'), findsOneWidget);
    // No dismiss affordance of any kind.
    expect(find.text('لاحقاً'), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('recommended mode offers a Later exit', (tester) async {
    await tester.pumpWidget(_pump(mandatory: false));

    expect(find.text('يتوفر تحديث'), findsWidgets);
    expect(find.text('لاحقاً'), findsOneWidget);
  });
}
