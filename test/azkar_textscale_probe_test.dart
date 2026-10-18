import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

Map<String, dynamic> fixtureRoot() => {
      'collections': [
        {
          'id': 'c1',
          'nameAr': 'أذكار الصباح',
          'nameEn': 'Morning',
          'items': [
            {'text': 'ذِكْرٌ لَهُ ثَلَاثٌ', 'count': 3},
            {'text': 'ذِكْرٌ وَاحِدٌ'},
          ],
        },
      ],
    };

Future<void> pumpAzkarAt2x(WidgetTester tester) async {
  final cubit = AzkarCubit(
    repository: AzkarRepository(loader: () async => fixtureRoot()),
  );
  addTearDown(cubit.close);
  await tester.pumpWidget(BlocProvider<AzkarCubit>.value(
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
      home: const AzkarScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('textScale 2.0: the browse list survives the layout',
      (tester) async {
    await pumpAzkarAt2x(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('٢ ذكر'), findsOneWidget);
  });

  testWidgets('textScale 2.0: the reciting list survives the layout',
      (tester) async {
    await pumpAzkarAt2x(tester);

    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'), findsOneWidget);
    expect(find.text('٣'), findsOneWidget);
  });
}
