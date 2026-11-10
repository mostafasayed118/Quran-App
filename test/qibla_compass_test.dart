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
  group('qiblaDeltaDeg', () {
    test('is the signed shortest turn, not a 0..360 arc', () {
      expect(qiblaDeltaDeg(137.2, 90), closeTo(47.2, 1e-9));
      expect(qiblaDeltaDeg(10, 350), closeTo(20, 1e-9));
      expect(qiblaDeltaDeg(350, 10), closeTo(-20, 1e-9));
      expect(qiblaDeltaDeg(137.2, 137.2), closeTo(0, 1e-9));
      expect(qiblaDeltaDeg(0, 180), closeTo(180, 1e-9));
    });
  });

  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
  });

  Future<void> pumpWithHeading(
    WidgetTester tester,
    StreamController<double> controller,
  ) async {
    // A tall phone surface: the hint below the dial lives under the fold on
    // the default 800x600 test window, which lazily skips building it.
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await repo.select(cairoCity);
    final cubit = QiblaCubit(
      city: repo,
      qibla: FakeQiblaService(),
      heading: HeadingService(streamFactory: () => controller.stream),
    );
    addTearDown(cubit.close);
    await cubit.start();
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<QiblaCubit>.value(value: cubit, child: app),
      home: const QiblaScreen(),
    );
  }

  testWidgets('lined up with the qibla shows the confirmation and a gold dial',
      (tester) async {
    final controller = StreamController<double>();
    addTearDown(controller.close);
    await pumpWithHeading(tester, controller);

    controller.add(137.2);
    await tester.pump();
    await tester.pump();

    expect(find.text('أنت تواجه القبلة'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('a few degrees off shows which way to turn', (tester) async {
    final controller = StreamController<double>();
    addTearDown(controller.close);
    await pumpWithHeading(tester, controller);

    controller.add(107.2);
    await tester.pump();
    await tester.pump();

    expect(find.text('أدر الهاتف ٣٠ درجة يمينًا'), findsOneWidget);
    expect(find.text('أنت تواجه القبلة'), findsNothing);
  });

  testWidgets('turning the other way says left, not 330 right', (tester) async {
    final controller = StreamController<double>();
    addTearDown(controller.close);
    await pumpWithHeading(tester, controller);

    controller.add(167.2);
    await tester.pump();
    await tester.pump();

    expect(find.text('أدر الهاتف ٣٠ درجة يسارًا'), findsOneWidget);
  });
}
