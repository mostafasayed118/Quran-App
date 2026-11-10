/// Opens the platform's store listing for this app.
///
/// A core port so the update feature and the router depend on the capability,
/// not on the `in_app_review` plugin.
abstract interface class StoreListingGateway {
  /// Opens the store page for this package; true when the platform accepted
  /// the request. Best-effort: never throws.
  Future<bool> open();
}
