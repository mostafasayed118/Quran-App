/// Throttles per-chunk download progress so the UI sees ~1% steps instead of
/// one state emit per network chunk (a multi-MB pack would otherwise rebuild
/// its rows thousands of times per install). Unknown totals fall back to a
/// 256 KiB byte window so a host without content-length still reports.
class ProgressThrottle {
  ProgressThrottle({this.percentStep = 1, this.byteStep = 256 * 1024});

  final int percentStep;
  final int byteStep;

  int _lastPercentBucket = -1;
  int _lastReportedBytes = 0;
  bool _reportedAny = false;

  bool shouldReport(int received, int total) {
    if (total <= 0) {
      if (!_reportedAny || received - _lastReportedBytes >= byteStep) {
        _reportedAny = true;
        _lastReportedBytes = received;
        return true;
      }
      return false;
    }
    final bucket = ((received * 100) ~/ total) ~/ percentStep;
    if (bucket != _lastPercentBucket) {
      _lastPercentBucket = bucket;
      return true;
    }
    return false;
  }
}
