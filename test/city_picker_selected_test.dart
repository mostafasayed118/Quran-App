import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'prayer_times_cubit_test.dart' show cairoCity;
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(
      db: db,
      loader: () async => [
        cairoCity.toJson(),
        {
          'id': 'riyadh',
          'nameAr': 'الرياض',
          'nameEn': 'Riyadh',
          'lat': 24.7136,
          'lng': 46.6753,
        },
      ],
    );
  });

  Future<void> pumpPicker(WidgetTester tester, CityPickerCubit cubit) async {
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<CityPickerCubit>.value(
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
        home: const CityPickerScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the persisted city is marked, and raw ids no longer render',
      (tester) async {
    await repo.select(cairoCity);
    final handle = tester.ensureSemantics();
    await pumpPicker(tester, CityPickerCubit(cityRepo: repo));

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('المدينة الحالية')), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.check_circle)).semanticLabel,
      'المدينة الحالية',
    );
    expect(find.text('cairo'), findsNothing);
    expect(find.text('riyadh'), findsNothing);

    handle.dispose();
  });

  testWidgets('with no persisted city, no row is marked', (tester) async {
    await pumpPicker(tester, CityPickerCubit(cityRepo: repo));

    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('the mark follows the persisted city after picking one',
      (tester) async {
    final cubit = CityPickerCubit(cityRepo: repo);
    await pumpPicker(tester, cubit);

    expect(find.byIcon(Icons.check_circle), findsNothing);

    await cubit.persist(cairoCity);
    await cubit.search('');
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
