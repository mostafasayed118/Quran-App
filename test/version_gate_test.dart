import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/version_gate.dart';
import 'package:quran_yahdi/core/domain/version_ack_store.dart';
import 'package:quran_yahdi/core/domain/version_policy.dart';
import 'package:quran_yahdi/core/domain/version_policy_source.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';
import 'package:quran_yahdi/features/update/data/version_policy_service.dart';

import 'support/test_db.dart';

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString('not found', 404);

  @override
  void close({bool force = false}) {}
}

class _OkAdapter implements HttpClientAdapter {
  _OkAdapter(this.body);

  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(body, 200);

  @override
  void close({bool force = false}) {}
}

class _StaticSource implements VersionPolicySource {
  _StaticSource(this.policy);

  final VersionPolicy? policy;

  @override
  Future<VersionPolicy?> fetch() async => policy;
}

class _MemoryAckStore implements VersionAckStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String latest) async => value = latest;
}

void main() {
  group('VersionPolicyService (network + cache)', () {
    test('a 200 with a valid policy is returned and cached', () async {
      final db = newTestDb();
      final body = jsonEncode({
        'min_supported': '1.0.0',
        'latest': '1.0.0',
      });
      final service = VersionPolicyService(
        db: db,
        client: Dio()..httpClientAdapter = _OkAdapter(body),
      );

      final policy = await service.fetch();

      expect(policy, isNotNull);
      // The cache got the raw document for the next cold start.
      expect(await service.read(), body);
    });

    test('an HTTP failure with no cache fails open (null policy, app starts)',
        () async {
      final db = newTestDb();
      final service = VersionPolicyService(
        db: db,
        client: Dio()..httpClientAdapter = _FailingAdapter(),
      );

      expect(await service.fetch(), isNull);
    });

    test('an HTTP failure serves the last known good policy from cache',
        () async {
      final db = newTestDb();
      final body = jsonEncode({
        'min_supported': '1.0.0',
        'latest': '1.0.0',
      });
      final writer = VersionPolicyService(
        db: db,
        client: Dio()..httpClientAdapter = _OkAdapter(body),
      );
      await writer.fetch(); // seeds the cache
      final reader = VersionPolicyService(
        db: db,
        client: Dio()..httpClientAdapter = _FailingAdapter(),
      );

      expect(await reader.fetch(), isNotNull);
    });

    test('a malformed remote document falls back to the cache, not the wire',
        () async {
      final db = newTestDb();
      final body = jsonEncode({
        'min_supported': '1.0.0',
        'latest': '1.0.0',
      });
      final writer = VersionPolicyService(
        db: db,
        client: Dio()..httpClientAdapter = _OkAdapter(body),
      );
      await writer.fetch();
      final reader = VersionPolicyService(
        db: db,
        client: Dio()..httpClientAdapter = _OkAdapter('{"bogus": true}'),
      );

      expect(await reader.fetch(), isNotNull);
    });

    test('a malformed remote document with no cache fails open', () async {
      final db = newTestDb();
      final service = VersionPolicyService(
        db: db,
        client: Dio()..httpClientAdapter = _OkAdapter('{"bogus": true}'),
      );

      expect(await service.fetch(), isNull);
    });
  });

  group('VersionGate', () {
    final mandatorySource = _StaticSource(const VersionPolicy(
      minSupported: AppVersion(2, 0, 0),
      latest: AppVersion(2, 0, 0),
    ));
    final optionalSource = _StaticSource(const VersionPolicy(
      minSupported: AppVersion(1, 0, 0),
      latest: AppVersion(9, 9, 9),
    ));

    test('before the first read lands the gate blocks nothing', () {
      final gate = VersionGate();
      expect(gate.decide(AppRoutes.home), isNull);
      expect(gate.decide(AppRoutes.azkar), isNull);
      expect(gate.shouldShowRecommendedPrompt, isFalse);
    });

    test('a valid mandatory policy blocks every route except /update',
        () async {
      final gate = VersionGate();
      gate.attach(
        source: mandatorySource,
        ackStore: _MemoryAckStore(),
        installed: const AppVersion(1, 0, 0),
      );
      await gate.settled;

      expect(gate.verdict, VersionVerdict.updateRequired);
      expect(gate.decide(AppRoutes.home), AppRoutes.update);
      expect(gate.decide(AppRoutes.azkar), AppRoutes.update);
      expect(gate.decide(AppRoutes.update), isNull);
    });

    test('a recommended policy does not block navigation', () async {
      final gate = VersionGate();
      gate.attach(
        source: optionalSource,
        ackStore: _MemoryAckStore(),
        installed: const AppVersion(1, 0, 0),
      );
      await gate.settled;

      expect(gate.verdict, VersionVerdict.updateRecommended);
      expect(gate.decide(AppRoutes.home), isNull);
      expect(gate.shouldShowRecommendedPrompt, isTrue);
    });

    test(
        'acknowledging the recommendation suppresses the prompt for that build',
        () async {
      final gate = VersionGate();
      final ack = _MemoryAckStore();
      gate.attach(
        source: optionalSource,
        ackStore: ack,
        installed: const AppVersion(1, 0, 0),
      );
      await gate.settled;

      await gate.acknowledgeRecommended();

      expect(gate.shouldShowRecommendedPrompt, isFalse);
      expect(ack.value, '9.9.9');
    });

    test('a null (unavailable) policy can never lock the user out', () async {
      final gate = VersionGate();
      gate.attach(
        source: _StaticSource(null),
        ackStore: _MemoryAckStore(),
        installed: const AppVersion(0, 0, 1),
      );
      await gate.settled;

      expect(gate.verdict, isNull);
      expect(gate.decide(AppRoutes.home), isNull);
    });
  });
}
