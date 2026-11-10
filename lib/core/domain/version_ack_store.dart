/// Persistence for "the user dismissed the optional update banner for build
/// X".
///
/// A core port: the gate reads it through the interface, so the drift adapter
/// stays in the feature's data layer.
abstract interface class VersionAckStore {
  /// The acknowledged recommendation key, or null when nothing was acked.
  Future<String?> read();

  /// Remembers [latest] as acknowledged.
  Future<void> write(String latest);
}
