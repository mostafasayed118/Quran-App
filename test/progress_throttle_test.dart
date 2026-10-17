import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/utils/progress_throttle.dart';

void main() {
  test('reports at most ~100 times for a known total', () {
    final throttle = ProgressThrottle();
    var reports = 0;
    for (var received = 1024; received <= 1000000; received += 1024) {
      if (throttle.shouldReport(received, 1000000)) reports++;
    }
    if (throttle.shouldReport(1000000, 1000000)) reports++;

    expect(reports, greaterThan(0));
    expect(reports, lessThanOrEqualTo(102));
  });

  test('reports the first chunk and the completion', () {
    final throttle = ProgressThrottle();

    expect(throttle.shouldReport(1, 100), isTrue);
    expect(throttle.shouldReport(100, 100), isTrue);
  });

  test('unknown total falls back to a byte-distance window', () {
    final throttle = ProgressThrottle();

    expect(throttle.shouldReport(1024, 0), isTrue);
    expect(throttle.shouldReport(2048, 0), isFalse);
    expect(throttle.shouldReport(300 * 1024, 0), isTrue);
  });
}
