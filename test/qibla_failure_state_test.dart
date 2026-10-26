import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/features/qibla/data/heading_service.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_cubit.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_state.dart';

import 'support/fakes.dart';

class _ThrowingCitySource implements CitySource {
  @override
  Future<City?> selectedCity() async {
    throw StateError('city lookup failed');
  }

  @override
  Future<void> select(City city) async {}
}

void main() {
  test('a heading sample cannot replace the failed state with ready', () async {
    final controller = StreamController<double>();
    addTearDown(controller.close);
    final cubit = QiblaCubit(
      city: _ThrowingCitySource(),
      qibla: FakeQiblaService(),
      heading: HeadingService(streamFactory: () => controller.stream),
    );
    addTearDown(cubit.close);

    final states = <QiblaState>[];
    final subscription = cubit.stream.listen(states.add);
    addTearDown(subscription.cancel);

    await cubit.start();
    expect(cubit.state, isA<QiblaFailed>());
    expect(states.whereType<QiblaReady>(), isEmpty);

    controller.add(123.0);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<QiblaFailed>());
    expect(states.whereType<QiblaReady>(), isEmpty);
    expect(states.whereType<QiblaFailed>(), isNotEmpty);
  });
}
