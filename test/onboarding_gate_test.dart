import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/onboarding_gate.dart';
import 'package:quran_yahdi/app/router.dart';
import 'package:quran_yahdi/core/domain/onboarding_status.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';

class _Status implements OnboardingStatusSource {
  _Status({this.completed = false});

  bool completed;
  bool throwOnRead = false;
  bool throwOnWrite = false;
  int writes = 0;

  @override
  Future<bool> isCompleted() async {
    if (throwOnRead) throw StateError('read');
    return completed;
  }

  @override
  Future<void> markCompleted() async {
    if (throwOnWrite) throw StateError('write');
    writes++;
    completed = true;
  }
}

void main() {
  test('an unattached gate never redirects', () {
    final gate = OnboardingGate();

    expect(gate.completed, isNull);
    expect(gate.decide(AppRoutes.home), isNull);
    expect(gate.decide(AppRoutes.quran), isNull);
  });

  test('a first run sends every route to the flow', () async {
    final gate = OnboardingGate()..attach(_Status());
    await Future<void>.delayed(Duration.zero);

    expect(gate.completed, isFalse);
    expect(gate.decide(AppRoutes.home), AppRoutes.onboarding);
    expect(gate.decide(AppRoutes.quran), AppRoutes.onboarding);
    // Already on the flow: stay.
    expect(gate.decide(AppRoutes.onboarding), isNull);
    // Sub-routes of the flow stay too: redirecting them would collapse the
    // pushed page and leave its pop with nothing to return to.
    expect(gate.decide(AppRoutes.onboardingCity), isNull);
  });

  test('the blocked route is restored after the flow', () async {
    final gate = OnboardingGate()..attach(_Status());
    await Future<void>.delayed(Duration.zero);

    const deepLink = '/quran/reader?surah=2&ayah=255';
    expect(gate.decide(deepLink), AppRoutes.onboarding);
    expect(gate.pendingLocation, deepLink);

    await gate.complete();

    expect(gate.decide(AppRoutes.onboarding), deepLink);
    expect(gate.pendingLocation, isNull);
  });

  test('finishing with no blocked route lands on home', () async {
    final gate = OnboardingGate()..attach(_Status());
    await Future<void>.delayed(Duration.zero);

    await gate.complete();

    expect(gate.decide(AppRoutes.onboarding), AppRoutes.home);
  });

  test('a completed user is never redirected', () async {
    final gate = OnboardingGate()..attach(_Status(completed: true));
    await Future<void>.delayed(Duration.zero);

    expect(gate.completed, isTrue);
    expect(gate.decide(AppRoutes.home), isNull);
    expect(gate.decide(AppRoutes.onboarding), AppRoutes.home);
  });

  test('completing writes through and notifies once', () async {
    final status = _Status();
    final gate = OnboardingGate()..attach(status);
    await Future<void>.delayed(Duration.zero);
    var notifications = 0;
    gate.addListener(() => notifications++);

    await gate.complete();
    await gate.complete();

    expect(status.writes, 1);
    expect(notifications, 1);
  });

  test('a failing write still completes the gate', () async {
    final gate = OnboardingGate()..attach(_Status()..throwOnWrite = true);
    await Future<void>.delayed(Duration.zero);

    await gate.complete();

    expect(gate.completed, isTrue);
  });

  test('an unreadable flag never traps the user behind the flow', () async {
    final gate = OnboardingGate()..attach(_Status()..throwOnRead = true);
    await Future<void>.delayed(Duration.zero);

    expect(gate.completed, isTrue);
    expect(gate.decide(AppRoutes.home), isNull);
  });

  test('reload picks up a flag written elsewhere', () async {
    final status = _Status();
    final gate = OnboardingGate()..attach(status);
    await Future<void>.delayed(Duration.zero);
    expect(gate.completed, isFalse);

    status.completed = true;
    await gate.reload();

    expect(gate.completed, isTrue);
  });

  test('the app router is wired to the gate', () async {
    addTearDown(AppRouter.onboardingGate.reset);
    AppRouter.onboardingGate.attach(_Status());
    await Future<void>.delayed(Duration.zero);

    expect(AppRouter.redirectFor(AppRoutes.home), AppRoutes.onboarding);

    await AppRouter.onboardingGate.complete();
    expect(AppRouter.redirectFor(AppRoutes.onboarding), AppRoutes.home);
  });

  test('a test that never attaches the gate still reads the route map', () {
    AppRouter.onboardingGate.reset();

    expect(AppRouter.redirectFor(AppRoutes.home), isNull);
    expect(
      AppRouter.router.configuration.routes,
      isNotEmpty,
      reason: 'the router must stay usable without DI',
    );
  });
}
