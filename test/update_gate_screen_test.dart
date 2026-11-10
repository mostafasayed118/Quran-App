import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/update/presentation/update_gate_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

Widget _pump({required bool mandatory}) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: UpdateGateScreen(
        mandatory: mandatory,
        onOpenStore: () async => true,
        onLater: () async {},
      ),
    );

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
