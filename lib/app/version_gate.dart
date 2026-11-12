import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../core/domain/version_ack_store.dart';
import '../core/domain/version_policy.dart';
import '../core/domain/version_policy_source.dart';
import '../core/utils/app_routes.dart';

/// The update gate, modeled on [OnboardingGate] (cached synchronous verdict,
/// `decide(location)` for the router, `refreshListenable` fan-out).
///
/// Before the first policy read lands [verdict] is null and [decide] never
/// blocks — exactly like the onboarding gate keeps test routers working on
/// whatever route they asked for.
///
/// Failure policy (fail-open): any read/refresh failure leaves [verdict] at
/// its previous value; before the first read it stays null → the app starts
/// normally. The last-known-good cache is applied when the network fails, so
/// a transient outage neither weakens nor wrongly strengthens enforcement.
class VersionGate extends ChangeNotifier {
  VersionPolicySource? _source;
  VersionAckStore? _ackStore;
  AppVersion? _installed;

  VersionVerdict? _verdict;
  String? _ackedLatest;
  bool _loading = false;

  /// The cached verdict; null until the first read lands.
  VersionVerdict? get verdict => _verdict;

  /// The resolved installed version; null until attached.
  AppVersion? get installed => _installed;

  /// True while a policy read is in flight (for diagnostics only).
  bool get isLoading => _loading;

  /// True when an *optional* update is available and not yet dismissed for
  /// this recommendation. Never true when the verdict is [VersionVerdict.updateRequired].
  bool get shouldShowRecommendedPrompt {
    if (_verdict != VersionVerdict.updateRecommended) return false;
    // Acked for this exact recommendation? Only a *new* `latest` re-prompts.
    return _ackedLatest != _recommendedKey;
  }

  String? get _recommendedKey => _latest?.toString();
  AppVersion? _latest;

  /// The route that fires the verdict-dependent first actions.
  Future<void> get settled => _settled ?? Future<void>.value();

  Future<void>? _settled;

  /// Points the gate at its policy source and starts the first read.
  /// The returned future completes when the first read settles.
  void attach({
    required VersionPolicySource source,
    required VersionAckStore ackStore,
    required AppVersion installed,
  }) {
    _source = source;
    _ackStore = ackStore;
    _installed = installed;
    _settled = reload();
  }

  /// Re-reads the ack flag (boot) — called once by [attach].
  Future<void> reload() async {
    if (_loading) return;
    _loading = true;
    try {
      final ackStore = _ackStore;
      if (ackStore != null) {
        try {
          _ackedLatest = await ackStore.read();
        } on Object catch (error, stackTrace) {
          appLog(
            'version gate ack read failed',
            name: 'quran_yahdi/version-gate',
            error: error.runtimeType,
            stackTrace: stackTrace,
          );
          _ackedLatest = null;
        }
      }
      final source = _source;
      if (source == null || _installed == null) return;
      final policy = await source.fetch();
      if (policy == null) {
        // Fail-open on the very first ever read; otherwise keep the cached
        // verdict (the fetch already consulted the on-disk cache).
        if (_verdict == null) return;
        return;
      }
      if (!policy.isPlausibleFor(_installed!)) {
        // A typo such as 99.0.0 must not wall every install; an implausible
        // jump is ignored until a human corrects the published document.
        appLog(
          'version policy rejected: min_supported is implausible',
          name: 'quran_yahdi/version-gate',
        );
        return;
      }
      _latest = policy.latest;
      final verdict = policy.verdictFor(_installed!);
      if (verdict == _verdict) return;
      _verdict = verdict;
      notifyListeners();
    } on Object catch (error, stackTrace) {
      appLog(
        'version gate reload failed',
        name: 'quran_yahdi/version-gate',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    } finally {
      _loading = false;
    }
  }

  /// The route to use for [location], or null to stay.
  ///
  /// Only a *valid* policy that marks the installed build as below the
  /// minimum forces navigation; everything else passes through untouched.
  String? decide(String location) {
    if (_verdict != VersionVerdict.updateRequired) return null;
    if (location == AppRoutes.update) return null;
    return AppRoutes.update;
  }

  /// Dismiss the optional-update prompt for this recommendation.
  Future<void> acknowledgeRecommended() async {
    final key = _recommendedKey;
    if (key == null) return;
    try {
      await _ackStore?.write(key);
    } on Object catch (error, stackTrace) {
      appLog(
        'version gate ack write failed',
        name: 'quran_yahdi/version-gate',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
    if (_ackedLatest == key) return;
    _ackedLatest = key;
    notifyListeners();
  }

  /// Test seam: reset every cached value (never called in production).
  @visibleForTesting
  void reset() {
    _source = null;
    _ackStore = null;
    _installed = null;
    _verdict = null;
    _ackedLatest = null;
    _latest = null;
  }
}
