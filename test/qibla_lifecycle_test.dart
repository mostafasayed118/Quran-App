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

/// Hands out one fresh controller stream per `headingStream()` call, so the
/// pause/resume re-acquisition is observable (the real service is a factory
/// too: `magnetometerEventStream()` returns a new stream every call).
class _TwoStreamFactory {
  final controllers = <StreamController<double>>[
    StreamController<double>(),
    StreamController<double>(),
  ];
  int calls = 0;

  Stream<double>? call() {
    final controller = controllers[calls];
    calls++;
    return controller.stream;
  }

  void close() {
    // Fire-and-forget: a listener-less single-subscription controller's
    // close() future never completes (no done event is ever delivered).
    for (final controller in controllers) {
      unawaited(controller.close());
    }
  }
}

void main() {
  late AppDatabase db;
  late CityRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
  });

  group('QiblaCubit heading lifecycle', () {
    test('pause cancels and retains the heading; resume re-acquires', () async {
      final factory = _TwoStreamFactory();
      addTearDown(factory.close);
      final cubit = QiblaCubit(
        city: repo,
        qibla: FakeQiblaService(),
        heading: HeadingService(streamFactory: factory.call),
      );
      addTearDown(cubit.close);
      await cubit.start();

      expect(factory.calls, 1);
      expect(factory.controllers[0].hasListener, isTrue);

      factory.controllers[0].add(90.0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.heading, 90.0);

      await cubit.pause();
      expect(factory.controllers[0].hasListener, isFalse,
          reason: 'pause must cancel the magnetometer subscription');
      expect(cubit.state.heading, 90.0,
          reason: 'the last heading stays displayed while paused');

      // A paused stream must not reach the cubit even if it somehow buffers.
      factory.controllers[0].add(45.0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.heading, 90.0);

      cubit.resume();
      expect(factory.calls, 2, reason: 'resume must call headingStream again');
      expect(factory.controllers[1].hasListener, isTrue);

      factory.controllers[1].add(17.0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.heading, 17.0);

      // The pre-pause subscription is dead: the old controller cannot emit.
      factory.controllers[0].add(200.0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.heading, 17.0);
    });

    test('resume is idempotent: an already-bound cubit is not re-bound',
        () async {
      final factory = _TwoStreamFactory();
      addTearDown(factory.close);
      final cubit = QiblaCubit(
        city: repo,
        qibla: FakeQiblaService(),
        heading: HeadingService(streamFactory: factory.call),
      );
      addTearDown(cubit.close);
      await cubit.start();

      cubit.resume();
      expect(factory.calls, 1);
    });
  });

  group('QiblaScreen app lifecycle', () {
    testWidgets('backgrounding pauses the cubit and resuming re-acquires',
        (tester) async {
      final factory = _TwoStreamFactory();
      addTearDown(factory.close);
      addTearDown(
        () => tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await repo.select(cairoCity);
      final cubit = QiblaCubit(
        city: repo,
        qibla: FakeQiblaService(),
        heading: HeadingService(streamFactory: factory.call),
      );
      addTearDown(cubit.close);
      await cubit.start();
      await pumpAppHost(
        tester,
        wrap: (app) => BlocProvider<QiblaCubit>.value(value: cubit, child: app),
        home: const QiblaScreen(),
      );

      expect(factory.controllers[0].hasListener, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(factory.controllers[0].hasListener, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(factory.calls, 2);
      expect(factory.controllers[1].hasListener, isTrue);
    });
  });
}
