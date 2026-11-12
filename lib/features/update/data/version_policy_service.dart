import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

/// When [versionPolicyCacheKey] was written. A separate key keeps the cached
/// document byte-compatible with the previous builds; a missing timestamp is
/// treated as stale (fail-open) because the old cache has no age evidence.
const String versionPolicyCacheAtKey = 'version_policy_cache_at';

/// Production policy source: fetch the remote document, fall back to the
/// last-known-good cache, never lock the user out (fail-open).
///
/// A release build must carry `QURAN_VERSION_POLICY_PUBLIC_KEY`; without it,
/// unsigned documents are rejected and the gate stays off. A configured key
/// requires a valid Ed25519 signature and an `expires_at`. The cache is
/// additionally age-bounded so a stale copy cannot outlive the publisher's
/// intent.
///
/// The payload is ~200 bytes of JSON, so decoding is done synchronously — an
/// isolate hop for it would be pure overhead. All failures degrade to null.
class VersionPolicyService implements VersionPolicySource, VersionPolicyCache {
  VersionPolicyService({
    required AppDatabase db,
    Dio? client,
    DateTime Function()? clock,
    String? publicKeyB64,
    bool? isRelease,
    Duration maxCacheAge = const Duration(days: 30),
  })  : _db = db,
        _clock = clock ?? DateTime.now,
        _publicKeyB64 = publicKeyB64 ?? policyPublicKeyB64,
        _isRelease = isRelease ?? kReleaseMode,
        _maxCacheAge = maxCacheAge,
        _client = client ??
            (Dio()
              ..options.connectTimeout = const Duration(seconds: 8)
              ..options.receiveTimeout = const Duration(seconds: 8));

  /// The compile-time Ed25519 public key (base64) a policy must be signed with.
  ///
  /// Set it in every release build via
  /// `--dart-define=QURAN_VERSION_POLICY_PUBLIC_KEY=…`. With a key, an unsigned
  /// or badly-signed policy is ignored (fail-open), so a compromised hosting
  /// account cannot wall installed apps. A release build with an empty key
  /// rejects every policy instead of trusting an unsigned one; debug builds
  /// keep the legacy unsigned path for local development.
  static const String policyPublicKeyB64 =
      String.fromEnvironment('QURAN_VERSION_POLICY_PUBLIC_KEY');

  /// The largest document this app will read. The real one is ~200 bytes.
  static const int maxPolicyBytes = 64 * 1024;

  final AppDatabase _db;
  final Dio _client;
  final DateTime Function() _clock;
  final String _publicKeyB64;
  final bool _isRelease;
  final Duration _maxCacheAge;
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
      if (!_hasRequiredExpiry(policy)) {
        // A signed policy without an expiry could be replayed forever; it is
        // ignored until the publisher adds one.
        appLog(
          'version policy missing required expiry',
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
      final cachedAt = await _readCachedAt();
      if (cachedAt == null) return null;
      if (_clock().difference(cachedAt) > _maxCacheAge) return null;
      final raw = await read();
      if (raw == null || raw.isEmpty || raw.length > maxPolicyBytes) {
        return null;
      }
      final decoded = jsonDecode(raw);
      final policy = VersionPolicy.fromJson(decoded);
      if (policy == null) return null;
      // The cache is a copy of a remote document, so it gets the same checks
      // as the network path: an expired, unsigned or unbounded copy enforces
      // nothing.
      if (!await _isAuthentic(decoded)) return null;
      if (!_hasRequiredExpiry(policy)) return null;
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
  /// A debug build without a key keeps the old unsigned path for local work.
  /// A release build without a key rejects every policy instead: the gate
  /// stays fail-open, so an omitted `--dart-define` can never turn a remote
  /// document into a kill-switch.
  Future<bool> _isAuthentic(Object? document) async {
    if (_publicKeyB64.isEmpty) return !_isRelease;
    if (document is! Map<String, Object?>) return false;
    final signature = document['signature'];
    if (signature is! String) return false;
    try {
      final publicKey = SimplePublicKey(
        base64Decode(_publicKeyB64),
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

  /// A signed policy must carry an expiry so a cached copy cannot be replayed
  /// indefinitely. Debug builds without a key keep the legacy unsigned shape.
  bool _hasRequiredExpiry(VersionPolicy policy) =>
      _publicKeyB64.isEmpty || policy.expiresAt != null;

  Future<DateTime?> _readCachedAt() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(versionPolicyCacheAtKey)))
        .getSingleOrNull();
    return DateTime.tryParse(row?.value ?? '');
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
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: versionPolicyCacheAtKey,
            value: _clock().toUtc().toIso8601String(),
          ),
        );
  }
}
