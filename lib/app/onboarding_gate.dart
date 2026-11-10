import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../core/domain/onboarding_status.dart';
import '../core/utils/app_routes.dart';

/// The router's first-run gate.
///
/// The redirect needs the answer synchronously, so the flag is cached here and
/// the gate notifies the router when it changes. The storage source is
/// attached after DI is configured; until then [completed] is null and
/// [decide] never redirects — which is what keeps a router built without DI
/// (widget tests) on its requested route.
///
/// A user who skips still counts as completed: the flow is a first-run step,
/// not a lock.
///
/// It is also the app's [OnboardingStatusSource], so the flow's finish/skip
/// goes through the same cache the redirect reads.
class OnboardingGate extends ChangeNotifier implements OnboardingStatusSource {
  OnboardingStatusSource? _source;
  bool? _completed;
  String? _pendingLocation;

  /// The cached flag; null until the first read lands.
  bool? get completed => _completed;

  /// The route that was blocked by the gate, restored after the flow.
  String? get pendingLocation => _pendingLocation;

  /// Optional seam invoked after the flow completes (finish or skip).
  /// Production wires this to the review prompt; tests leave it null.
  /// Called synchronously after the gate flips; must not throw.
  void Function()? onCompleted;

  /// Points the gate at its storage and starts the first read.
  void attach(OnboardingStatusSource source) {
    _source = source;
    unawaited(reload());
  }

  /// Re-reads the flag (boot, or after an import).
  Future<void> reload() async {
    final source = _source;
    if (source == null) return;
    bool completed;
    try {
      completed = await source.isCompleted();
    } on Object catch (error, stackTrace) {
      appLog('onboarding gate read failed',
          name: 'quran_yahdi/onboarding', error: error, stackTrace: stackTrace);
      // A flag we cannot read must never trap the user behind the flow.
      completed = true;
    }
    if (completed == _completed) return;
    _completed = completed;
    notifyListeners();
  }

  /// Marks the flow done (finish or skip) and lets the router move on.
  Future<void> complete() async {
    if (_completed == true) return;
    try {
      await _source?.markCompleted();
    } on Object catch (error, stackTrace) {
      appLog('onboarding gate write failed',
          name: 'quran_yahdi/onboarding', error: error, stackTrace: stackTrace);
    }
    if (_completed == true) return;
    _completed = true;
    notifyListeners();
    try {
      onCompleted?.call();
    } on Object catch (error, stackTrace) {
      // A failing review seam must never break the completion path.
      appLog(
        'onboarding completion seam failed',
        name: 'quran_yahdi/onboarding',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
  }

  /// The cached answer, or the storage read when nothing landed yet.
  ///
  /// An unreadable flag answers `true` — the flow never traps the user.
  @override
  Future<bool> isCompleted() async {
    final cached = _completed;
    if (cached != null) return cached;
    final source = _source;
    if (source == null) return true;
    try {
      return await source.isCompleted();
    } on Object {
      return true;
    }
  }

  /// Same as [complete] — the flow's write path.
  @override
  Future<void> markCompleted() => complete();

  /// The route to use for [location], or null to stay.
  ///
  /// Before the first read lands, nothing is redirected. On first run every
  /// route is replaced by the flow, and the blocked location is remembered so
  /// a notification tap (or a deep link) survives the detour.
  String? decide(String location) {
    final completed = _completed;
    if (completed == null) return null;
    // Any route inside the flow (`/onboarding`, `/onboarding/city`, ...) is
    // part of the flow: redirecting those would collapse the pushed page and
    // leave its `pop` with nothing to return to.
    final atOnboarding = location == AppRoutes.onboarding ||
        location.startsWith('${AppRoutes.onboarding}/');
    if (!completed) {
      if (atOnboarding) return null;
      _pendingLocation = location;
      return AppRoutes.onboarding;
    }
    if (!atOnboarding) return null;
    final next = _pendingLocation ?? AppRoutes.home;
    _pendingLocation = null;
    return next;
  }

  /// Clears the cache and the attached source (tests only).
  @visibleForTesting
  void reset() {
    _source = null;
    _completed = null;
    _pendingLocation = null;
  }
}
