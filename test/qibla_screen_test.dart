import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/qibla/data/qibla_service.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_cubit.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

const cairoCity = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

class FakeQiblaService implements QiblaService {
  @override
  double bearingDeg(CityCoordinates c) => 137.2;
}

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpHost(WidgetTester tester, {required bool seeded}) async {
    if (seeded) await repo.select(cairoCity);
    final cubit = QiblaCubit(city: repo, qibla: FakeQiblaService());
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<QiblaCubit>.value(
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
        home: const QiblaScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  test('cubit with no selection emits ready with null city and bearing',
      () async {
    final cubit = QiblaCubit(city: repo, qibla: FakeQiblaService());
    await cubit.reload();
    expect(cubit.state.city, isNull);
    expect(cubit.state.bearing, isNull);
    await cubit.close();
  });

  testWidgets('seeded city renders the bearing dial with the rotated arrow',
      (tester) async {
    await pumpHost(tester, seeded: true);

    final rotated = find.byWidgetPredicate(
      (w) =>
          w is Transform &&
          w.child is Icon &&
          (w.child as Icon).icon == Icons.navigation &&
          !w.transform.isIdentity(),
    );
    expect(rotated, findsOneWidget);
    expect(find.textContaining('عن الشمال'), findsOneWidget);
    expect(find.textContaining('١٣٧'), findsOneWidget);
  });

  testWidgets('no city shows the prompt and the picker button', (tester) async {
    await pumpHost(tester, seeded: false);

    expect(find.text('لم تُحدَّد مدينة بعد'), findsOneWidget);
    expect(find.text('اختر مدينتك'), findsOneWidget);
  });
}
