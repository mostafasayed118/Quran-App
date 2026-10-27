import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/location_service.dart';
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
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
  });

  Future<CityPickerCubit> pumpHost(
    WidgetTester tester, {
    LocationService? location,
  }) async {
    final cubit = CityPickerCubit(cityRepo: repo, location: location);
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(
      BlocProvider<CityPickerCubit>.value(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('HOME'),
                    TextButton(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.push(
                          MaterialPageRoute<void>(
                            builder: (_) => const Scaffold(
                              body: Center(child: Text('UNDER')),
                            ),
                          ),
                        );
                        navigator.push(
                          MaterialPageRoute<void>(
                            builder: (_) => BlocProvider<CityPickerCubit>.value(
                              value: cubit,
                              child: const CityPickerScreen(),
                            ),
                          ),
                        );
                      },
                      child: const Text('OPEN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('اختر مدينتك'), findsOneWidget);
    return cubit;
  }

  Future<void> tapLocateAndLeavePicker(WidgetTester tester) async {
    await tester.tap(find.text('استخدم موقعي'));
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('اختر مدينتك'), findsNothing);
    expect(find.text('UNDER'), findsOneWidget);
  }

  testWidgets('a late successful locate does not pop the underlying route',
      (tester) async {
    final gate = Completer<CityCoordinates?>();
    await pumpHost(
      tester,
      location: LocationService(resolver: () => gate.future),
    );

    await tapLocateAndLeavePicker(tester);

    gate.complete(const CityCoordinates(30.0444, 31.2357));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('UNDER'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect((await repo.selectedCity())?.id, 'cairo');
  });

  testWidgets(
      'a late failed locate does not show a snackbar on the '
      'underlying route', (tester) async {
    final gate = Completer<CityCoordinates?>();
    await pumpHost(
      tester,
      location: LocationService(resolver: () => gate.future),
    );

    await tapLocateAndLeavePicker(tester);

    gate.complete(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('UNDER'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
