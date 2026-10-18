/// Guard against a lying/compromised host streaming unbounded bytes: allow
/// up to 2x the declared size plus 64 KiB slack, capped by an optional
/// absolute [ceiling]. A non-positive declared size falls back to the
/// ceiling — or to the bare 64 KiB slack when there is no ceiling.
int guardedByteCap(int declared, {int? ceiling}) {
  if (declared <= 0) return ceiling ?? 65536;
  final cap = declared * 2 + 65536;
  final limit = ceiling;
  return limit == null || cap <= limit ? cap : limit;
}
