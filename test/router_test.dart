import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/router.dart';

/// Every `GoRoute` in the tree, including the ones nested inside the shell
/// that renders the bottom bar. The approved map is unchanged; only its
/// nesting moved.
Iterable<GoRoute> _allRoutes(List<RouteBase> routes) sync* {
  for (final route in routes) {
    if (route is GoRoute) {
      yield route;
      yield* _allRoutes(route.routes);
    } else if (route is ShellRoute) {
      yield* _allRoutes(route.routes);
    }
  }
}

void main() {
  test('router exposes the approved 14-route map', () {
    final paths = _allRoutes(AppRouter.router.configuration.routes)
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
