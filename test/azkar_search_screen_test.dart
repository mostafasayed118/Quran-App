import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

Map<String, dynamic> _root() => {
      'collections': [
        {
          'id': 'c1',
          'nameAr': 'أذكار الصباح',
          'nameEn': 'Morning',
          'items': [
            {'text': 'اللَّهُمَّ بِكَ أَصْبَحْنَا', 'count': 1},
          ],
        },
        {
          'id': 'c2',
          'nameAr': 'أذكار النوم',
          'nameEn': 'Sleep',
          'items': [
            {'text': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', 'count': 1},
          ],
        },
      ],
    };

Future<void> _pumpAzkar(WidgetTester tester, {double scale = 1.0}) async {
  final cubit = AzkarCubit(
    repository: AzkarRepository(loader: () async => _root()),
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
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const AzkarScreen(),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('typing shows matching items with their collection name',
      (tester) async {
    await _pumpAzkar(tester);

    await _type(tester, 'باسمك');

    expect(find.text('نتائج البحث: ١'), findsOneWidget);
    expect(find.text('بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا'), findsOneWidget);
    expect(find.text('أذكار النوم'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsNothing);
  });

  testWidgets('an unmatched query shows the localized empty state',
      (tester) async {
    await _pumpAzkar(tester);

    await _type(tester, 'لا يوجد');

    expect(find.text('لا توجد أذكار مطابقة لبحثك'), findsOneWidget);
  });

  testWidgets('clearing the query restores the collections list',
      (tester) async {
    await _pumpAzkar(tester);

    await _type(tester, 'النوم');
    expect(find.text('أذكار الصباح'), findsNothing);

    await _type(tester, '');
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('أذكار النوم'), findsOneWidget);
  });

  testWidgets('tapping a result opens its collection in the reciting view',
      (tester) async {
    await _pumpAzkar(tester);

    await _type(tester, 'باسمك');
    await tester.tap(find.text('بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا'));
    await tester.pump();
    await tester.pump();

    expect(find.text('١'), findsOneWidget);
    expect(find.text('أذكار النوم'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);
  });

  testWidgets('textScale 2.0: search field and results survive the layout',
      (tester) async {
    await _pumpAzkar(tester, scale: 2.0);

    await _type(tester, 'باسمك');

    expect(tester.takeException(), isNull);
    expect(find.text('بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا'), findsOneWidget);
  });
}
