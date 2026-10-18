import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_cubit.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  const fieldLabels = [
    'ذهب (جرام)',
    'فضة (جرام)',
    'سعر جرام الذهب',
    'سعر جرام الفضة',
    'النقد المعروض',
    'الديون',
  ];

  Future<void> pumpZakat(WidgetTester tester, {double textScale = 1.0}) async {
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const ZakatScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> enterByLabel(
      WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextField, label);
    await tester.scrollUntilVisible(field, 60,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  testWidgets('nisab segments and all six fields meet the 48 dp bar (360-wide)',
      (tester) async {
    usePhoneViewport(tester);
    await pumpZakat(tester);

    final segments = find.descendant(
      of: find.byType(SegmentedButton<bool>),
      matching: find.byType(TextButton),
    );
    expect(segments, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      final size = tester.getSize(segments.at(i));
      expect(size.height, greaterThanOrEqualTo(48.0),
          reason: 'segment $i measured ${size.height} dp tall');
    }

    for (final label in fieldLabels) {
      final field = find.widgetWithText(TextField, label);
      await tester.scrollUntilVisible(field, 60,
          scrollable: find.byType(Scrollable).first);
      final size = tester.getSize(field);
      expect(size.height, greaterThanOrEqualTo(48.0),
          reason: 'field "$label" measured ${size.height} dp tall');
    }
  });

  testWidgets('inputs and the nisab switch announce labels to screen readers',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpZakat(tester);

    expect(
      tester.getSemantics(find.byType(TextField).first).label,
      contains('ذهب (جرام)'),
    );
    expect(find.bySemanticsLabel('العتبة: الذهب'), findsOneWidget);
    expect(find.bySemanticsLabel('العتبة: الفضة'), findsOneWidget);

    handle.dispose();
  });

  testWidgets(
      'textScale 2.0 on a 360-wide phone: form, verdict and footnote survive',
      (tester) async {
    usePhoneViewport(tester);
    await pumpZakat(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);

    await enterByLabel(tester, 'سعر جرام الفضة', '1');
    await enterByLabel(tester, 'النقد المعروض', '1000');
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('الزكاة الواجبة'), 60,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('الزكاة الواجبة'), findsOneWidget);
    expect(find.textContaining('٢٥'), findsOneWidget);

    await tester.scrollUntilVisible(find.textContaining('النسبة ثابتة'), 60,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('النسبة ثابتة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
