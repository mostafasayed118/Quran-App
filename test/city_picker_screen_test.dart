import 'package:drift/native.dart';
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

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = CityRepository(db: db, loader: () async => [
      {'id': 'cairo', 'nameAr': 'القاهرة', 'nameEn': 'Cairo', 'lat': 30.0444, 'lng': 31.2357},
      {'id': 'riyadh', 'nameAr': 'الرياض', 'nameEn': 'Riyadh', 'lat': 24.7136, 'lng': 46.6753},
      {'id': 'dubai', 'nameAr': 'دبي', 'nameEn': 'Dubai', 'lat': 25.2048, 'lng': 55.2708},
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('search filters live and picking persists then pops', (tester) async {
    final cubit = CityPickerCubit(cityRepo: repo);
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
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider<CityPickerCubit>.value(
                      value: cubit,
                      child: const CityPickerScreen(),
                    ),
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('اختر مدينتك'), findsOneWidget);
    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.text('الرياض'), findsOneWidget);
    expect(find.text('دبي'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'cai');
    await tester.pumpAndSettle();
    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.text('الرياض'), findsNothing);

    await tester.tap(find.text('القاهرة'));
    await tester.pumpAndSettle();

    expect(find.text('اختر مدينتك'), findsNothing);
    final selected = await repo.selectedCity();
    expect(selected, isNotNull);
    expect(selected!.id, 'cairo');
  });
}
