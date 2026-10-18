import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';
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

  Future<void> pumpHost(
    WidgetTester tester, {
    required bool seeded,
    HeadingService? heading,
    TextScaler? textScaler,
  }) async {
    if (seeded) await repo.select(cairoCity);
    final cubit = QiblaCubit(
      city: repo,
      qibla: FakeQiblaService(),
      heading: heading,
    );
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
        builder: textScaler == null
            ? null
            : (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: child!,
                ),
        home: const QiblaScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('textScale 2.0: the static dial survives the layout',
      (tester) async {
    await pumpHost(tester,
        seeded: true, textScaler: const TextScaler.linear(2.0));

    expect(tester.takeException(), isNull);
    expect(find.text('القاهرة'), findsOneWidget);
    expect(find.textContaining('عن الشمال'), findsOneWidget);
    expect(find.textContaining('المقياس ثابت'), findsOneWidget);
  });

  testWidgets('textScale 2.0: the live dial survives the layout',
      (tester) async {
    await pumpHost(
      tester,
      seeded: true,
      textScaler: const TextScaler.linear(2.0),
      heading: HeadingService(streamFactory: () => Stream.value(90.0)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('المقياس حي'), findsOneWidget);
    expect(find.textContaining('عن الشمال'), findsOneWidget);
  });

  testWidgets('a11y: the bearing line and the static hint are announced',
      (tester) async {
    await pumpHost(tester, seeded: true);
    final semantics = tester.ensureSemantics();

    final bearingLabel =
        tester.getSemantics(find.textContaining('عن الشمال')).label;
    expect(bearingLabel, contains('عن الشمال'));
    final hintLabel =
        tester.getSemantics(find.textContaining('المقياس ثابت')).label;
    expect(hintLabel, contains('المقياس ثابت'));

    semantics.dispose();
  });
}
