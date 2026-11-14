part of 'injector.dart';

/// Schedules the review prompt off the onboarding completion seam.
///
/// Both the finish and the skip paths flow through here; the service itself
/// is double-guarded (process-wide flag + persisted one-shot marker).
void _scheduleReviewPrompt() {
  unawaited(getIt<ReviewService>().maybeRequestAfterOnboarding());
}

/// The update gate's policy source, the ack store for the optional prompt,
/// and the review service. All fail-open: the gate can only enforce a valid
/// remote policy, and the review seam schedules at most one prompt per
/// install after the user finishes (or skips) onboarding.
void _registerVersionGate(AppDatabase db) {
  getIt.registerLazySingleton<VersionPolicyService>(
      () => VersionPolicyService(db: db));
  getIt.registerLazySingleton<VersionPolicySource>(
      () => getIt<VersionPolicyService>());
  getIt.registerLazySingleton<VersionAckStore>(() => DriftVersionAckStore(db));
  // The installed version arrives asynchronously (PackageInfo) — main.dart
  // attaches the gate behind the first frame.
  getIt.registerLazySingleton<VersionGate>(() => AppRouter.versionGate);
  getIt.registerLazySingleton<StoreListingGateway>(
      () => InAppReviewStoreListing());
}

void _registerOnboardingAndSettings(AppDatabase db) {
  getIt.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepository(db));
  // The review prompt hangs off the same completion seam as the gate: finish
  // and skip both call [OnboardingGate.complete], which fires this at most
  // once per install, never at cold start.
  getIt.registerLazySingleton<ReviewService>(() => ReviewService(db: db));
  // One instance serves both the router gate and the flow: the gate caches the
  // flag for the synchronous redirect, and a finish/skip notifies the router.
  getIt.registerLazySingleton<OnboardingGate>(() => AppRouter.onboardingGate
    ..onCompleted = _scheduleReviewPrompt
    ..attach(getIt<OnboardingRepository>()));
  getIt.registerLazySingleton<OnboardingStatusSource>(
      () => getIt<OnboardingGate>());
  getIt.registerLazySingleton<AppLocaleRepository>(
      () => AppLocaleRepository(db));
  getIt.registerLazySingleton<AppLocaleSource>(
      () => getIt<AppLocaleRepository>());
  // One controller feeds the app root (MaterialApp.locale) and the settings
  // row; the app entry point calls load() behind the first frame.
  getIt.registerLazySingleton<AppLocaleController>(
      () => AppLocaleController(getIt<AppLocaleSource>()));
  getIt.registerLazySingleton<AppThemeRepository>(() => AppThemeRepository(db));
  getIt
      .registerLazySingleton<AppThemeSource>(() => getIt<AppThemeRepository>());
  // Same shape for the appearance: the root rebuilds `MaterialApp.themeMode`
  // and the settings row shows the current choice.
  getIt.registerLazySingleton<AppThemeController>(
      () => AppThemeController(getIt<AppThemeSource>()));
  getIt.registerLazySingleton<PrayerSkinRepository>(
      () => PrayerSkinRepository(db));
  getIt.registerLazySingleton<PrayerSkinSource>(
      () => getIt<PrayerSkinRepository>());
  // The prayer skin is opt-in and device-scoped: the root reads it behind the
  // first frame, and the settings row flips it.
  getIt.registerLazySingleton<PrayerSkinController>(
      () => PrayerSkinController(getIt<PrayerSkinSource>()));
}

/// Clears the one-time guard so a test can build a fresh graph.
///
/// `getIt.reset()` alone leaves [_configured] true, turning the next
/// [configureDependencies] into a silent no-op. A test that resets the
/// locator must call this too, or it keeps asserting against the old graph.
@visibleForTesting
void resetDependenciesForTest() {
  _configured = false;
  // The router owns two static gates that outlive the locator. Reset them
  // here so a test that discards the graph cannot inherit a verdict or an
  // onboarding state from the previous test.
  AppRouter.versionGate.reset();
  AppRouter.onboardingGate.reset();
}
