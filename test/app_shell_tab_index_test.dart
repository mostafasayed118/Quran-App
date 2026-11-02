import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/app_shell.dart';
import 'package:quran_yahdi/core/utils/app_routes.dart';

void main() {
  test('the four root destinations map to their own tab', () {
    expect(AppTabs.indexOf(AppRoutes.home), 0);
    expect(AppTabs.indexOf(AppRoutes.quran), 1);
    expect(AppTabs.indexOf(AppRoutes.prayerTimes), 2);
    expect(AppTabs.indexOf(AppRoutes.azkar), 3);
  });

  test('nested destinations highlight their parent tab', () {
    expect(AppTabs.indexOf(AppRoutes.juzIndex), 1);
    expect(AppTabs.indexOf(AppRoutes.quranSearch), 1);
    expect(AppTabs.indexOf(AppRoutes.prayerMonth), 2);
    expect(AppTabs.indexOf(AppRoutes.prayerSettings), 2);
  });

  test('an unknown location falls back to Home', () {
    expect(AppTabs.indexOf('/not-a-route'), 0);
  });

  test('a prefix that is not a child path does not match', () {
    expect(AppTabs.indexOf('${AppRoutes.quran}-extra'), 0);
  });
}
