import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_radius.dart';
import '../core/utils/app_routes.dart';
import '../features/recitation/presentation/playback/mini_player_bar.dart';
import '../l10n/app_localizations.dart';

/// Top-level destinations, in bar order.
///
/// Deliberately four: Home is still the full service directory, so a fifth
/// "More" tab would only repeat it. Detail routes (reader, recitation, library,
/// qibla, settings …) open above the shell without the bar.
abstract final class AppTabs {
  static const paths = <String>[
    AppRoutes.home,
    AppRoutes.quran,
    AppRoutes.prayerTimes,
    AppRoutes.azkar,
  ];

  /// The tab that owns [location].
  ///
  /// Nested destinations inside the shell (`/quran/juz`, `/quran/search`,
  /// `/prayer-times/month`, `/prayer-times/settings`) belong to their parent
  /// tab; matching by prefix keeps the right destination highlighted and stops
  /// its tap from short-circuiting as "already selected".
  static int indexOf(String location) {
    for (var index = 0; index < paths.length; index++) {
      final path = paths[index];
      if (location == path || location.startsWith('$path/')) return index;
    }
    return 0;
  }
}

/// Persistent bottom navigation for the four primary destinations.
///
/// The shell wraps the page in an outer [Scaffold] so the page keeps its own
/// [Scaffold] (app bar, snack bars, bottom sheets) and the bar owns only the
/// strip below it.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: child,
      // A Column, not `bottomSheet`: the bottom navigation area is excluded
      // from the body's height, so the playing strip pushes content up instead
      // of covering it. The strip is zero-height while nothing is playing.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          NavigationBar(
            selectedIndex: AppTabs.indexOf(location),
            backgroundColor: colors.surface,
            indicatorColor: colors.primaryContainer,
            // A translucent indicator over a card-coloured bar reads as a
            // tint; the full radius keeps it consistent with the card scale.
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: AppRadius.pillAll,
            ),
            onDestinationSelected: (index) {
              if (index == AppTabs.indexOf(location)) return;
              context.go(AppTabs.paths[index]);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: loc.home,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book),
                label: loc.quran,
              ),
              NavigationDestination(
                icon: const Icon(Icons.access_time_outlined),
                selectedIcon: const Icon(Icons.access_time),
                label: loc.prayerTimes,
              ),
              NavigationDestination(
                icon: const Icon(Icons.spa_outlined),
                selectedIcon: const Icon(Icons.spa),
                label: loc.azkar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
