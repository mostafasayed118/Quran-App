import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/features/qibla/data/compass_calibration.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';
import 'package:quran_yahdi/features/qibla/data/qibla_service.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_cubit.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_screen.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_state.dart';

import 'support/host.dart';

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
  test('fieldLooksDisturbed rejects weak, strong and vertical fields', () {
    expect(fieldLooksDisturbed(const MagneticSample(20, 20, 0)), isFalse);
    expect(fieldLooksDisturbed(const MagneticSample(1, 1, 0)), isTrue);
    expect(fieldLooksDisturbed(const MagneticSample(100, 0, 0)), isTrue);
    expect(fieldLooksDisturbed(const MagneticSample(0, 0, 50)), isTrue);
  });

  test('the calibration hint needs 10 bad and 20 good samples', () async {
    final field = StreamController<MagneticSample>();
    final calibration = CompassCalibration(field: () => field.stream);
    final events = <bool>[];
    final sub = calibration.needsCalibrationStream()!.listen(events.add);
    addTearDown(() async {
      await field.close();
      await sub.cancel();
    });

    for (var i = 0; i < 9; i++) {
      field.add(const MagneticSample(1, 1, 0));
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events, isEmpty);

    field.add(const MagneticSample(1, 1, 0));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events, [true]);

    for (var i = 0; i < 19; i++) {
      field.add(const MagneticSample(20, 20, 0));
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events, [true]);

    field.add(const MagneticSample(20, 20, 0));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(events, [true, false]);
  });

  testWidgets('the screen shows the hint when the field is disturbed',
      (tester) async {
    final heading = StreamController<double>();
    final field = StreamController<MagneticSample>();
    final cubit = QiblaCubit(
      city: const _City(),
      qibla: const QiblaService(),
      heading: HeadingService(streamFactory: () => heading.stream),
      calibration: CompassCalibration(field: () => field.stream),
    );
    addTearDown(() async {
      await field.close();
      await heading.close();
      await cubit.close();
    });

    await cubit.start();

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      appShell(
        home: BlocProvider<QiblaCubit>.value(
          value: cubit,
          child: const QiblaScreen(),
        ),
      ),
    );
    heading.add(90);
    for (var i = 0; i < 10; i++) {
      field.add(const MagneticSample(1, 1, 0));
    }
    await tester.pump();

    expect((cubit.state as QiblaReady).calibrationNeeded, isTrue);
    expect(find.textContaining('الاتجاه غير دقيق'), findsOneWidget);

    for (var i = 0; i < 20; i++) {
      field.add(const MagneticSample(20, 20, 0));
    }
    await tester.pump();

    expect(find.textContaining('الاتجاه غير دقيق'), findsNothing);
  });
}
