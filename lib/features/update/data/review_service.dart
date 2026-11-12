import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../core/db/app_database.dart';
import '../../../core/domain/review_prompt.dart';

/// Settings-table key for the one-shot review marker. Deliberately outside
/// the backup whitelist: a restore on a fresh install should not suppress the
/// (single, once-per-install) prompt.
const String reviewRequestedKey = 'review_requested';

/// The delay between the user finishing (or skipping) the onboarding flow and
/// the review prompt. Never during the flow itself, never at cold start.
const Duration kReviewPromptDelay = Duration(milliseconds: 1500);

/// The platform side of the review API is the core port [ReviewGateway];
/// production wires [InAppReviewGateway].
class InAppReviewGateway implements ReviewGateway {
  @override
  Future<bool> isAvailable() async {
    try {
      return await InAppReview.instance.isAvailable();
    } on Object catch (error, stackTrace) {
      appLog(
        'review availability probe failed',
        name: 'quran_yahdi/review',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> requestReview() async {
    await InAppReview.instance.requestReview();
  }
}

/// Pure policy for the review prompt. No clock, no I/O — tests pin it fully.
///
/// The eligibility model is deliberately minimal:
/// - [ReviewGate] fires only after the onboarding flow completes
///   (finish or skip) — a user-initiated completion moment, never at cold
///   start, never during religious or reading flows;
/// - once per install: after the first request the marker is written BEFORE
///   the platform call so a crash between the two cannot re-prompt;
/// - nothing about the user's reading/adhkar/tasbeeh/prayer activity is
///   inspected, counted or transmitted.
@immutable
class ReviewEligibility {
  const ReviewEligibility(
      {required this.onboardingCompleted, required this.alreadyRequested});

  final bool onboardingCompleted;
  final bool alreadyRequested;

  bool get shouldRequest => onboardingCompleted && !alreadyRequested;
}

/// Wires the onboarding completion seam to the Play In-App Review API.
///
/// Registered in DI; attached to the onboarding gate's completion callback so
/// both the finish and the skip paths flow through the same code path.
class ReviewService {
  ReviewService({
    required AppDatabase db,
    ReviewGateway? gateway,
    Future<void> Function(Duration)? delayer,
    Duration delay = kReviewPromptDelay,
  })  : _db = db,
        _gateway = gateway ?? InAppReviewGateway(),
        _delayer = delayer ?? Future<void>.delayed,
        _delay = delay;

  final AppDatabase _db;
  final ReviewGateway _gateway;
  final Future<void> Function(Duration) _delayer;
  final Duration _delay;

  bool _requestedInProcess = false;

  /// Whether the one-shot request has already happened (this process or a
  /// previous install). Exposed for diagnostics and tests.
  Future<bool> get alreadyRequested => _readRequested();

  /// Called by the onboarding gate when the flow completes (finish or skip).
  Future<void> maybeRequestAfterOnboarding() async {
    if (_requestedInProcess) return;
    try {
      final eligibility = ReviewEligibility(
        // The only caller is the onboarding-completion seam, so completion is
        // true by construction; keeping the predicate explicit is the point.
        onboardingCompleted: true,
        alreadyRequested: await _readRequested(),
      );
      if (!eligibility.shouldRequest) {
        _requestedInProcess = true;
        return;
      }
      // Mark before asking — the store quota and this flag both aim for
      // "at most once per install".
      await _writeRequested();
      _requestedInProcess = true;
      unawaited(_requestAfterDelay());
    } on Object catch (error, stackTrace) {
      appLog(
        'review prompt scheduling failed',
        name: 'quran_yahdi/review',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _requestAfterDelay() async {
    try {
      await _delayer(_delay);
      if (!await _gateway.isAvailable()) return;
      // Never blocks: the store decides whether a dialog shows up.
      await _gateway.requestReview();
    } on Object catch (error, stackTrace) {
      appLog(
        'review prompt request failed',
        name: 'quran_yahdi/review',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _readRequested() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(reviewRequestedKey)))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> _writeRequested() async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: reviewRequestedKey,
            value: 'true',
          ),
        );
  }
}
