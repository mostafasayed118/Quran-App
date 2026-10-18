import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/asma/data/asma_repository.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_cubit.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

List<Map<String, dynamic>> stressedFixture() => [
      {
        'n': 1,
        'nameAr': 'الرحمن',
        'nameEn': 'The Most Compassionate',
        'meaningAr': 'ذو الرحمة الواسعة التي وسعت كل شيء',
        'meaningEn': 'The Most Compassionate, Owner of all-embracing mercy',
      },
      {
        'n': 2,
        'nameAr': 'الرحيم',
        'nameEn': 'The Most Merciful',
        'meaningAr': 'النازل بالرحمة',
        'meaningEn': 'The Most Merciful',
      },
    ];

Future<void> pumpAsmaAt2x(WidgetTester tester) async {
  final cubit = AsmaCubit(
    repository: AsmaRepository(loader: () async => stressedFixture()),
  );
  addTearDown(cubit.close);
  await tester.pumpWidget(BlocProvider<AsmaCubit>.value(
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
            .copyWith(textScaler: const TextScaler.linear(2.0)),
        child: child!,
      ),
      home: const AsmaScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('textScale 2.0 on a 360-wide phone: the grid survives',
      (tester) async {
    usePhoneViewport(tester);
    await pumpAsmaAt2x(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('الرحمن'), findsOneWidget);
    expect(find.text('الرحيم'), findsOneWidget);
  });

  testWidgets('textScale 2.0: the meanings sheet survives', (tester) async {
    usePhoneViewport(tester);
    await pumpAsmaAt2x(tester);

    await tester.tap(find.text('الرحمن'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ذو الرحمة الواسعة التي وسعت كل شيء'), findsOneWidget);
  });

  testWidgets('grid tiles meet the 48 dp touch-target bar', (tester) async {
    usePhoneViewport(tester);
    await pumpAsmaAt2x(tester);

    final tiles = find.byType(InkWell);
    expect(tiles, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      final size = tester.getSize(tiles.at(i));
      expect(
        size.height >= 48.0 && size.width >= 48.0,
        isTrue,
        reason: 'tile $i measured ${size.height} x ${size.width}',
      );
    }
  });
}
