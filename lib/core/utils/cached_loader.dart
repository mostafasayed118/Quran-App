/// Single-flight memoization for a lazy async load: the first [load] starts
/// the wrapped function and caches its in-flight future, so concurrent
/// callers share one invocation and its result. A success stays cached for
/// the loader's lifetime; a failure clears the cache and rethrows, so the
/// next call retries.
class CachedLoader<T> {
  CachedLoader(this._load);

  final Future<T> Function() _load;

  Future<T>? _cache;

  Future<T> load() {
    return _cache ??= _load().then<T>(
      (value) => value,
      onError: (Object error, StackTrace stackTrace) {
        _cache = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }
}
