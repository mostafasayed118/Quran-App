import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/router.dart';

void main() {
  test('router exposes the approved 14-route map', () {
    final paths = AppRouter.router.configuration.routes
        .whereType<GoRoute>()
        .map((r) => r.path)
        .toSet();
    expect(
        paths,
        containsAll(<String>[
          '/home',
          '/quran',
          '/recitation',
          '/library',
          '/prayer-times',
          '/qibla',
          '/azkar',
          '/tasbih',
          '/duas',
          '/worship',
          '/zakat',
          '/hijri',
          '/asma',
          '/settings',
        ]));
  });
}
