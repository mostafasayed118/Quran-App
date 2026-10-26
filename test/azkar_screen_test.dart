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

void main() {
  testWidgets('browsing lists collections with item counts', (tester) async {
    final cubit = AzkarCubit(
      repository: AzkarRepository(loader: () async => fixtureRoot()),
    );
    addTearDown(cubit.close);
    await cubit.start();
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
        home: const AzkarScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('٢ ذكر'), findsOneWidget);
  });

  testWidgets(
      'tapping a collection opens items; taps decrement the chip; done dims',
      (tester) async {
    final cubit = AzkarCubit(
      repository: AzkarRepository(loader: () async => fixtureRoot()),
    );
    addTearDown(cubit.close);
    await cubit.start();
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
        home: const AzkarScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    expect(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'), findsOneWidget);
    expect(find.text('٣'), findsOneWidget);

    await tester.tap(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'));
    await tester.pumpAndSettle();
    expect(find.text('٢'), findsOneWidget);

    await tester.tap(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('أذكار الصباح'), findsOneWidget);
  });
}
