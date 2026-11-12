import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/di/injector.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/domain/version_ack_store.dart';
import 'package:quran_yahdi/core/domain/version_policy.dart';
import 'package:quran_yahdi/core/domain/version_policy_source.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';

import 'support/fakes.dart';

class _StaticPolicy implements VersionPolicySource {
  @override
  Future<VersionPolicy?> fetch() async => const VersionPolicy(
        minSupported: AppVersion(1, 0, 0),
        latest: AppVersion(1, 0, 0),
      );
}

class _NoAck implements VersionAckStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String latest) async {}
}

void main() {
  tearDown(() async {
    await getIt.reset();
    resetDependenciesForTest();
  });

  test('the reset hook lets a second configure build a fresh graph', () async {
    await configureDependencies();
    final first = getIt<CityRepository>();

    await getIt.reset();
    // Without the hook this second configure would return immediately and
    // `first` would still be the registered instance.
    resetDependenciesForTest();
    await configureDependencies(
      citiesLoader: () async => [cairoCity.toJson()],
    );

    final second = getIt<CityRepository>();
    expect(identical(first, second), isFalse);
    expect(await second.search(''), hasLength(1));
  });

  test('the reset hook clears the router gates', () async {
    final gate = AppRouter.versionGate;
    gate.attach(
      source: _StaticPolicy(),
      ackStore: _NoAck(),
      installed: const AppVersion(1, 0, 0),
    );
    await gate.settled;
    expect(gate.verdict, isNotNull);

    resetDependenciesForTest();

    expect(gate.verdict, isNull);
  });
}
