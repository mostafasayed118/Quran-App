/// The platform side of the in-app review API.
///
/// A core port so the review service never touches the plugin directly and
/// tests never need it.
abstract interface class ReviewGateway {
  /// Whether the Play surface will (probably) show the dialog.
  Future<bool> isAvailable();

  /// Fire-and-forget; the store decides whether a dialog appears.
  Future<void> requestReview();
}
