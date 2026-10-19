import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/location_service.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_cubit.dart';
import 'package:quran_yahdi/features/prayer/presentation/city_picker/city_picker_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'prayer_times_cubit_test.dart' show cairoCity;
import 'support/test_db.dart';

class _RecordingLocation extends LocationService {
  _RecordingLocation() : super(resolver: () async => null);

  bool opened = false;

  @override
  Future<void> openLocationSettings() async {
    opened = true;
  }
}

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
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

  testWidgets('a failed locate offers a working location-settings action',
      (tester) async {
    final location = _RecordingLocation();
    await pumpPicker(
      tester,
      CityPickerCubit(cityRepo: repo, location: location),
    );

    await tester.tap(find.text('استخدم موقعي'));
    await tester.pumpAndSettle();

    expect(find.text('تعذّر تحديد الموقع — اختر يدويًا'), findsOneWidget);
    expect(find.text('إعدادات الموقع'), findsOneWidget);

    await tester.tap(find.text('إعدادات الموقع'));
    await tester.pump();

    expect(location.opened, isTrue);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'without a location service the hint still shows and the action '
      'is a safe no-op', (tester) async {
    await pumpPicker(tester, CityPickerCubit(cityRepo: repo));

    await tester.tap(find.text('استخدم موقعي'));
    await tester.pumpAndSettle();

    expect(find.text('تعذّر تحديد الموقع — اختر يدويًا'), findsOneWidget);

    await tester.tap(find.text('إعدادات الموقع'));
    await tester.pump();

    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
