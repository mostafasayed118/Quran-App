/// One page of results from a limit/cursor source.
class Page<T> {
  const Page({required this.items, required this.hasMore});

  final List<T> items;

  /// True when the source reports at least one more page.
  final bool hasMore;
}

/// A request for one page of a limit/cursor source.
class PageRequest {
  const PageRequest({required this.limit, this.cursor});

  final int limit;

  /// Opaque provider cursor. The adapter passes it straight back to the
  /// provider; it is never an offset guessed by the UI.
  final String? cursor;
}

/// Contract for a remote catalog that can grow without bound.
///
/// Any new external API that returns a large catalog must implement this and
/// page at the provider (limit + cursor). Fetching the whole catalog and
/// slicing it in memory is explicitly not compliant.
abstract interface class PagedSource<T> {
  Future<Page<T>> fetchPage(PageRequest request);
}
