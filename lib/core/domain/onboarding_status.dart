/// The first-run flag seam.
///
/// Lives in `core/domain` because two features read it — the onboarding flow
/// owns it, the home dashboard advertises it — and a feature's presentation
/// layer must not import another feature's data layer.
///
/// The flag never gates the app: it only decides whether Home advertises the
/// setup flow. A user who skips must still reach every screen.
abstract interface class OnboardingStatusSource {
  /// True once the user finished or skipped the flow.
  Future<bool> isCompleted();

  /// Marks the flow as finished (or skipped); the Home card disappears.
  Future<void> markCompleted();
}
