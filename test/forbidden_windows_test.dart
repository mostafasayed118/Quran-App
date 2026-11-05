import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/prayer/domain/forbidden_windows.dart';

void main() {
  final fajr = DateTime(2026, 11, 5, 4, 45);
  final sunrise = DateTime(2026, 11, 5, 6, 10);
  final dhuhr = DateTime(2026, 11, 5, 11, 40);
  final asr = DateTime(2026, 11, 5, 14, 42);
  final maghrib = DateTime(2026, 11, 5, 17, 4);

  test('derives the three windows from the day times', () {
    final windows = forbiddenWindowsFor(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
    );

    expect(windows, hasLength(3));
    expect(windows[0].kind, ForbiddenWindowKind.afterFajr);
    expect(windows[0].start, fajr);
    expect(windows[0].end, sunrise);
    expect(windows[1].kind, ForbiddenWindowKind.zenith);
    expect(windows[1].start,
        dhuhr.subtract(const Duration(minutes: kZenithLeadMinutes)));
    expect(windows[1].end, dhuhr);
    expect(windows[2].kind, ForbiddenWindowKind.afterAsr);
    expect(windows[2].start, asr);
    expect(windows[2].end, maghrib);
  });

  test('a reversed window is dropped instead of rendered negative', () {
    final windows = forbiddenWindowsFor(
      fajr: sunrise,
      sunrise: fajr,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
    );

    expect(windows, hasLength(2));
    expect(windows.map((w) => w.kind),
        isNot(contains(ForbiddenWindowKind.afterFajr)));
  });
}
