import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_cubit.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_screen.dart';

import 'support/fakes.dart';
import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
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
    await cubit.start();
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<QiblaCubit>.value(value: cubit, child: app),
      home: const QiblaScreen(),
      textScale: textScaler?.scale(1.0),
    );
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
    final controller = StreamController<double>();
    addTearDown(controller.close);
    await pumpHost(
      tester,
      seeded: true,
      textScaler: const TextScaler.linear(2.0),
      heading: HeadingService(streamFactory: () => controller.stream),
    );
    controller.add(90.0);
    await tester.pump();
    await tester.pump();

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
