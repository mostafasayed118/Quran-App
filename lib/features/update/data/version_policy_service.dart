import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../core/db/app_database.dart';
import '../../../core/domain/version_policy.dart';
import '../../../core/domain/version_policy_source.dart';
import '../../../core/utils/canonical_json.dart';

/// The compile-time policy endpoint (the owner's Cloudflare Pages site).
///
/// Overridable for tests and for a staging page via
/// `flutter build apk --dart-define=QURAN_VERSION_POLICY_URL=https://...`,
/// and force-disabled entirely with `--dart-define=QURAN_VERSION_POLICY_URL=off`
/// (the app then never touches the network for the update gate).
const String productionVersionPolicyUrl =
    'https://quranyahdi.pages.dev/version.json';

String versionPolicyUrl() {
  const override = String.fromEnvironment('QURAN_VERSION_POLICY_URL');
  if (override == 'off') return '';
  if (override.isEmpty) return productionVersionPolicyUrl;
  // An override must not downgrade the transport: this document decides
  // whether the app keeps running, so a plaintext endpoint is refused.
  return Uri.tryParse(override)?.scheme == 'https' ? override : '';
}

/// Settings-table cache key. Deliberately NOT in the backup whitelist — a
/// cache must not travel to a fresh install.
const String versionPolicyCacheKey = 'version_policy_cache';

/// Production policy source: fetch the remote document, fall back to the
/// last-known-good cache, never lock the user out (fail-open).
///
/// The payload is ~200 bytes of JSON, so decoding is done synchronously — an
/// isolate hop for it would be pure overhead. All failures degrade to null.
class VersionPolicyService implements VersionPolicySource, VersionPolicyCache {
  VersionPolicyService({
    required AppDatabase db,
    Dio? client,
    DateTime Function()? clock,
  })  : _db = db,
        _clock = clock ?? DateTime.now,
        _client = client ??
            (Dio()
              ..options.connectTimeout = const Duration(seconds: 8)
              ..options.receiveTimeout = const Duration(seconds: 8));

  /// The compile-time Ed25519 public key (base64) a policy must be signed with.
  ///
  /// Empty by default, which leaves the previous behaviour intact. Setting
  /// `--dart-define=QURAN_VERSION_POLICY_PUBLIC_KEY=…` makes the document a
  /// signed one: an unsigned or badly-signed policy is then ignored (fail
  /// open), so a compromised hosting account can no longer wall every
  /// installed app.
  static const String policyPublicKeyB64 =
      String.fromEnvironment('QURAN_VERSION_POLICY_PUBLIC_KEY');

  /// The largest document this app will read. The real one is ~200 bytes.
  static const int maxPolicyBytes = 64 * 1024;

  final AppDatabase _db;
  final Dio _client;
  final DateTime Function() _clock;
  Future<VersionPolicy?>? _inFlight;

  @override
  Future<VersionPolicy?> fetch() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _fetch();
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    }).ignore();
    return future;
  }

  Future<VersionPolicy?> _fetch() async {
    final url = versionPolicyUrl();
    if (url.isEmpty) {
      // Force-disabled at build time; the gate stays fail-open forever.
      return null;
    }
    try {
      final response = await _client.get<String>(url);
      final body = response.data;
      if (response.statusCode != 200 || body == null || body.isEmpty) {
        return await _fromCache();
      }
      if (body.length > maxPolicyBytes) {
        // A document far larger than the real one is either corrupt or an
        // attempt to make the parse expensive; never trust it.
        return await _fromCache();
      }
      final decoded = jsonDecode(body);
      final policy = VersionPolicy.fromJson(decoded);
      if (policy == null) {
        // Malformed remote document: fall back to the cache, not to the
        // network's claim.
        return await _fromCache();
      }
      if (!await _isAuthentic(decoded)) {
        appLog(
          'version policy signature rejected',
          name: 'quran_yahdi/version-gate',
        );
        return await _fromCache();
      }
      if (policy.isExpiredAt(_clock())) {
        // A stale document must not wall an install.
        appLog('version policy expired', name: 'quran_yahdi/version-gate');
        return null;
      }
      try {
        await write(body);
      } on Object catch (error, stackTrace) {
        // A cache write failure must not weaken the verdict we just computed.
        appLog(
          'version policy cache write failed',
          name: 'quran_yahdi/version-gate',
          error: error.runtimeType,
          stackTrace: stackTrace,
        );
      }
      return policy;
    } on Object catch (error, stackTrace) {
      appLog(
        'version policy fetch failed',
        name: 'quran_yahdi/version-gate',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
      return await _fromCache();
    }
  }

  Future<VersionPolicy?> _fromCache() async {
    try {
      final raw = await read();
      if (raw == null || raw.isEmpty || raw.length > maxPolicyBytes) {
        return null;
      }
      final decoded = jsonDecode(raw);
      final policy = VersionPolicy.fromJson(decoded);
      if (policy == null) return null;
      // The cache is a copy of a remote document, so it gets the same checks
      // as the network path: an expired or unsigned copy enforces nothing.
      if (!await _isAuthentic(decoded)) return null;
      if (policy.isExpiredAt(_clock())) return null;
      return policy;
    } on Object catch (error, stackTrace) {
      appLog(
        'version policy cache unreadable',
        name: 'quran_yahdi/version-gate',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Whether [document] carries a valid signature from the configured key.
  ///
  /// Inert (always true) while [policyPublicKeyB64] is empty, so the gate
  /// keeps working exactly as before until the owner activates signing.
  Future<bool> _isAuthentic(Object? document) async {
    if (policyPublicKeyB64.isEmpty) return true;
    if (document is! Map<String, Object?>) return false;
    final signature = document['signature'];
    if (signature is! String) return false;
    try {
      final publicKey = SimplePublicKey(
        base64Decode(policyPublicKeyB64),
        type: KeyPairType.ed25519,
      );
      final unsigned = Map<String, Object?>.from(document)..remove('signature');
      return await Ed25519().verify(
        utf8.encode(canonicalJson(unsigned)),
        signature: Signature(base64Decode(signature), publicKey: publicKey),
      );
    } on Object {
      return false;
    }
  }

  @override
  Future<String?> read() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(versionPolicyCacheKey)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> write(String rawJson) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: versionPolicyCacheKey,
            value: rawJson,
          ),
        );
  }
}
