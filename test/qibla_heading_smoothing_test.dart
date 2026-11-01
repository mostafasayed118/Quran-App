import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';
import 'package:quran_yahdi/features/qibla/data/qibla_service.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_cubit.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_state.dart';

class _City implements CitySource {
  const _City();

  @override
  Future<City?> selectedCity() async => const City(
        id: 'cairo',
        nameAr: 'القاهرة',
        nameEn: 'Cairo',
        lat: 30.0444,
        lng: 31.2357,
      );

  @override
  Future<void> select(City city) async {}
}

void main() {
  test('shortestAngleDeltaDeg returns the signed shortest turn', () {
    expect(shortestAngleDeltaDeg(10, 350), 20);
    expect(shortestAngleDeltaDeg(350, 10), -20);
    expect(shortestAngleDeltaDeg(180, 0), 180);
    expect(shortestAngleDeltaDeg(0, 180), 180);
  });

  test('smoothHeadingDeg is a no-op on the first sample and snaps big turns',
      () {
    expect(smoothHeadingDeg(90, 92), closeTo(90.6, 1e-9));
    expect(smoothHeadingDeg(350, 355), closeTo(351.5, 1e-9));
    expect(smoothHeadingDeg(10, 5), closeTo(8.5, 1e-9));
    expect(smoothHeadingDeg(90, 130), 130);
  });

  test('the cubit filters jitter but passes the first sample exactly',
      () async {
    final heading = StreamController<double>.broadcast();
    final cubit = QiblaCubit(
      city: const _City(),
      qibla: const QiblaService(),
      heading: HeadingService(streamFactory: () => heading.stream),
    );
    addTearDown(() async {
      await cubit.close();
      await heading.close();
    });

    await cubit.start();
    heading.add(90);
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as QiblaReady).heading, 90);

    heading.add(95);
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as QiblaReady).heading, closeTo(91.5, 1e-9));

    heading.add(95);
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as QiblaReady).heading, closeTo(92.55, 1e-9));

    heading.add(95);
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as QiblaReady).heading, closeTo(93.285, 1e-9));
  });

  test('a resumed stream re-seeds the filter instead of dragging', () async {
    final controllers = <StreamController<double>>[];
    final cubit = QiblaCubit(
      city: const _City(),
      qibla: const QiblaService(),
      heading: HeadingService(streamFactory: () {
        final controller = StreamController<double>.broadcast();
        controllers.add(controller);
        return controller.stream;
      }),
    );
    addTearDown(() async {
      await cubit.close();
      for (final controller in controllers) {
        await controller.close();
      }
    });

    await cubit.start();
    controllers[0].add(90);
    await Future<void>.delayed(Duration.zero);
    expect((cubit.state as QiblaReady).heading, 90);

    await cubit.pause();
    cubit.resume();
    controllers[1].add(92);
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as QiblaReady).heading, 92);
  });
}
