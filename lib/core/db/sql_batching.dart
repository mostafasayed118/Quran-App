/// SQLite caps the number of host parameters in a statement at 999 (the value
/// of SQLITE_MAX_VARIABLE_NUMBER in the common build). An `IN (...)` built from
/// a user-sized bookmark set must be split below that bound, or the query fails
/// with "too many SQL variables" past 999 entries.
const int kMaxSqlVariables = 999;

/// Splits [items] into slices of at most [size] entries.
///
/// The slices preserve input order and are never empty for a non-empty input.
Iterable<List<T>> sqlBatches<T>(
  List<T> items, {
  int size = kMaxSqlVariables,
}) sync* {
  assert(size > 0);
  for (var start = 0; start < items.length; start += size) {
    final end = start + size < items.length ? start + size : items.length;
    yield items.sublist(start, end);
  }
}
