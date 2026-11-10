import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/domain/onboarding_status.dart';
import 'package:quran_yahdi/core/domain/version_ack_store.dart';
import 'package:quran_yahdi/core/domain/version_policy.dart';
import 'package:quran_yahdi/core/domain/version_policy_source.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';

class _Status implements OnboardingStatusSource {
  _Status({this.completed = true});

  bool completed;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async => completed = true;
}

class _MandatorySource implements VersionPolicySource {
  const _MandatorySource();

  @override
  Future<VersionPolicy?> fetch() async => const VersionPolicy(
        minSupported: AppVersion(2, 0, 0),
        latest: AppVersion(2, 0, 0),
      );
}

class _MemoryAckStore implements VersionAckStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String latest) async => value = latest;
}

void main() {
  test('a mandatory policy in the app router blocks every route to /update',
      () async {
    addTearDown(AppRouter.onboardingGate.reset);
    addTearDown(AppRouter.versionGate.reset);
    AppRouter.onboardingGate.attach(_Status(completed: true));
    await Future<void>.delayed(Duration.zero);
    AppRouter.versionGate.attach(
      source: const _MandatorySource(),
      ackStore: _MemoryAckStore(),
      installed: const AppVersion(1, 0, 0),
    );
    await AppRouter.versionGate.settled;

    expect(AppRouter.redirectFor(AppRoutes.home), AppRoutes.update);
    expect(AppRouter.redirectFor(AppRoutes.update), isNull);
  });

  test('the router stays navigable when the version gate never attaches', () {
    AppRouter.versionGate.reset();
    expect(AppRouter.redirectFor(AppRoutes.home), isNull);
  });
}
