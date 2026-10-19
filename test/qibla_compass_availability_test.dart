import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';
import 'package:quran_yahdi/features/qibla/data/qibla_service.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_cubit.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

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
    db = newTestDb();
    repo = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
  });

  group('QiblaCubit compass availability', () {
    test('no heading service at all marks the compass unavailable', () async {
      final cubit = QiblaCubit(city: repo, qibla: FakeQiblaService());
      await cubit.reload();
      expect(cubit.state.compassUnavailable, isTrue);
      expect(cubit.state.heading, isNull);
      await cubit.close();
    });

    test('a null stream (no magnetometer) marks the compass unavailable',
        () async {
      final cubit = QiblaCubit(
        city: repo,
        qibla: FakeQiblaService(),
        heading: HeadingService(streamFactory: () => null),
      );
      await cubit.reload();
      expect(cubit.state.compassUnavailable, isTrue);
      await cubit.close();
    });

    test(
        'a stream error marks the compass unavailable instead of being '
        'swallowed twice', () async {
      final controller = StreamController<double>();
      addTearDown(controller.close);
      final cubit = QiblaCubit(
        city: repo,
        qibla: FakeQiblaService(),
        heading: HeadingService(streamFactory: () => controller.stream),
      );
      controller.addError(StateError('NO_SENSOR'));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.compassUnavailable, isTrue);
      expect(cubit.state.heading, isNull);
      await cubit.close();
    });

    test('a heading sample keeps the compass live', () async {
      final controller = StreamController<double>();
      addTearDown(controller.close);
      final cubit = QiblaCubit(
        city: repo,
        qibla: FakeQiblaService(),
        heading: HeadingService(streamFactory: () => controller.stream),
      );
      await cubit.reload();
      expect(cubit.state.compassUnavailable, isFalse);
      controller.add(90.0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.compassUnavailable, isFalse);
      expect(cubit.state.heading, 90.0);
      await cubit.close();
    });

    test('an error after a sample clears the stale heading', () async {
      final controller = StreamController<double>();
      addTearDown(controller.close);
      final cubit = QiblaCubit(
        city: repo,
        qibla: FakeQiblaService(),
        heading: HeadingService(streamFactory: () => controller.stream),
      );
      controller.add(90.0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.heading, 90.0);
      controller.addError(StateError('sensor died'));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.compassUnavailable, isTrue);
      expect(cubit.state.heading, isNull);
      await cubit.close();
    });
  });

  group('QiblaScreen static-mode hint', () {
    Future<void> pumpHost(WidgetTester tester,
        {HeadingService? heading}) async {
      await repo.select(cairoCity);
      final cubit = QiblaCubit(
        city: repo,
        qibla: FakeQiblaService(),
        heading: heading,
      );
      addTearDown(cubit.close);
      await pumpAppHost(
        tester,
        wrap: (app) => BlocProvider<QiblaCubit>.value(value: cubit, child: app),
        home: const QiblaScreen(),
      );
    }

    testWidgets('without any sensor the screen explains the static dial',
        (tester) async {
      await pumpHost(tester);
      expect(find.text('المقياس حي'), findsNothing);
      expect(
        find.text('المقياس ثابت — لا يتوفر اتجاه مباشر على هذا الجهاز'),
        findsOneWidget,
      );
    });

    testWidgets('a live heading shows only the live footnote', (tester) async {
      await pumpHost(
        tester,
        heading: HeadingService(streamFactory: () => Stream.value(90.0)),
      );
      expect(find.text('المقياس حي'), findsOneWidget);
      expect(find.textContaining('المقياس ثابت'), findsNothing);
    });

    testWidgets('a dead sensor stream (error) surfaces the static-mode hint',
        (tester) async {
      await pumpHost(
        tester,
        heading: HeadingService(
          streamFactory: () => Stream<double>.error(StateError('NO_SENSOR')),
        ),
      );
      expect(find.text('المقياس حي'), findsNothing);
      expect(find.textContaining('المقياس ثابت'), findsOneWidget);
    });
  });
}
