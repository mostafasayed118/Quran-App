import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_cubit.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_screen.dart';

import 'support/fakes.dart';
import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late CityRepository repo;
  late StreamController<double> controller;
  late QiblaCubit cubit;

  setUp(() async {
    final db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    controller = StreamController<double>();
    await repo.select(cairoCity);
    cubit = QiblaCubit(
      city: repo,
      qibla: FakeQiblaService(),
      heading: HeadingService(streamFactory: () => controller.stream),
    );
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
    // Fire-and-forget: a listener-less single-subscription controller's
    // close() future never completes (no done event is ever delivered).
    unawaited(controller.close());
  });

  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
  ]) {
    testWidgets('$state pauses the magnetometer stream', (tester) async {
      addTearDown(
        () => tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await pumpAppHost(
        tester,
        wrap: (app) => BlocProvider<QiblaCubit>.value(value: cubit, child: app),
        home: const QiblaScreen(),
      );

      expect(controller.hasListener, isTrue);

      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();

      expect(
        controller.hasListener,
        isFalse,
        reason: '$state must pause the magnetometer subscription',
      );
    });
  }
}
