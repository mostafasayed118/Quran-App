import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/review_prompt.dart';
import 'package:quran_yahdi/features/update/data/review_service.dart';

import 'support/test_db.dart';

class _FakeGateway implements ReviewGateway {
  _FakeGateway({this.available = true, this.requestError});

  bool available;
  Object? requestError;
  int availabilityChecks = 0;
  int requests = 0;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<void> requestReview() async {
    if (requestError != null) throw requestError!;
    requests++;
  }
}

void main() {
  group('ReviewService (one-shot)', () {
    test('the first completion requests a review exactly once', () async {
      final db = newTestDb();
      final gateway = _FakeGateway();
      final service = ReviewService(
        db: db,
        gateway: gateway,
        delayer: (_) async {},
      );

      await service.maybeRequestAfterOnboarding();
      await pumpEventQueue();

      expect(gateway.requests, 1);
      expect(await service.alreadyRequested, isTrue);
    });

    test('a second completion in the same process requests nothing', () async {
      final db = newTestDb();
      final gateway = _FakeGateway();
      final service = ReviewService(
        db: db,
        gateway: gateway,
        delayer: (_) async {},
      );

      await service.maybeRequestAfterOnboarding();
      await service.maybeRequestAfterOnboarding();
      await pumpEventQueue();

      expect(gateway.requests, 1);
    });

    test('a fresh process honours the persisted one-shot marker', () async {
      final db = newTestDb();
      final first = ReviewService(
        db: db,
        gateway: _FakeGateway(),
        delayer: (_) async {},
      );
      await first.maybeRequestAfterOnboarding();

      final gateway = _FakeGateway();
      final second = ReviewService(
        db: db,
        gateway: gateway,
        delayer: (_) async {},
      );
      await second.maybeRequestAfterOnboarding();

      expect(gateway.availabilityChecks, 0);
      expect(gateway.requests, 0);
    });

    test('an unavailable Play surface never throws and never blocks', () async {
      final db = newTestDb();
      final gateway = _FakeGateway(available: false);
      final service = ReviewService(
        db: db,
        gateway: gateway,
        delayer: (_) async {},
      );

      await service.maybeRequestAfterOnboarding();
      await pumpEventQueue();

      expect(gateway.requests, 0);
      expect(await service.alreadyRequested, isTrue);
    });

    test('a failing plugin is swallowed and never reported to the user',
        () async {
      final db = newTestDb();
      final gateway = _FakeGateway(requestError: StateError('plugin boom'));
      final service = ReviewService(
        db: db,
        gateway: gateway,
        delayer: (_) async {},
      );

      // Must not throw.
      await service.maybeRequestAfterOnboarding();
      await pumpEventQueue();

      expect(await service.alreadyRequested, isTrue);
    });

    test('the delay elapses before the gateway is consulted', () async {
      final db = newTestDb();
      final gateway = _FakeGateway();
      final delayLog = <int>[];
      final service = ReviewService(
        db: db,
        gateway: gateway,
        delayer: (d) async {
          delayLog.add(d.inMilliseconds);
        },
        delay: const Duration(seconds: 3),
      );

      await service.maybeRequestAfterOnboarding();

      expect(delayLog, [3000]);
    });
  });

  group('ReviewEligibility', () {
    test('not eligible before onboarding completes', () {
      expect(
        const ReviewEligibility(
          onboardingCompleted: false,
          alreadyRequested: false,
        ).shouldRequest,
        isFalse,
      );
    });

    test('eligible exactly once onboarding completes', () {
      expect(
        const ReviewEligibility(
          onboardingCompleted: true,
          alreadyRequested: false,
        ).shouldRequest,
        isTrue,
      );
    });

    test('never eligible after a request, however favourable', () {
      expect(
        const ReviewEligibility(
          onboardingCompleted: true,
          alreadyRequested: true,
        ).shouldRequest,
        isFalse,
      );
    });
  });
}
