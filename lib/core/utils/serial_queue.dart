/// Runs asynchronous tasks one at a time, in submission order.
///
/// Two overlapping "read the current value, then write it" operations can
/// finish out of order: the older write lands last and the stored state is the
/// stale one. Queueing the writes removes that class of race without making
/// the caller wait on the UI.
class SerialQueue {
  Future<void> _tail = Future<void>.value();

  /// Runs [task] after every task submitted before it has settled.
  ///
  /// A failing task does not block the queue: its error is delivered to the
  /// caller and the next task still runs.
  Future<T> add<T>(Future<T> Function() task) {
    final next = _tail.then((_) => task());
    _tail = next.then((_) {}, onError: (Object _) {});
    return next;
  }
}
