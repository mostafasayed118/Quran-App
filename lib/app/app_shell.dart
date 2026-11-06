import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/layout/app_breakpoints.dart';
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

/// One top-level destination, shared by the bar and the rail.
typedef _Tab = ({
  IconData icon,
  IconData selectedIcon,
  String label,
});

/// Persistent navigation for the four primary destinations.
///
/// The shell wraps the page in an outer [Scaffold] so the page keeps its own
/// [Scaffold] (app bar, snack bars, bottom sheets) and the shell owns only the
/// navigation surface. Below [AppBreakpoints.expanded] that surface is the
/// bottom bar; from 840 dp it becomes a leading navigation rail, which returns
/// the vertical space a tablet/landscape window has to spare.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final selectedIndex = AppTabs.indexOf(location);

    final tabs = <_Tab>[
      (
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: loc.home,
      ),
      (
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
        label: loc.quran,
      ),
      (
        icon: Icons.access_time_outlined,
        selectedIcon: Icons.access_time,
        label: loc.prayerTimes,
      ),
      (
        icon: Icons.spa_outlined,
        selectedIcon: Icons.spa,
        label: loc.azkar,
      ),
    ];

    void select(int index) {
      if (index == selectedIndex) return;
      context.go(AppTabs.paths[index]);
    }

    if (!AppBreakpoints.isExpanded(context)) {
      return Scaffold(
        body: child,
        // A Column, not `bottomSheet`: the bottom navigation area is excluded
        // from the body's height, so the playing strip pushes content up
        // instead of covering it. The strip is zero-height while nothing plays.
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayerBar(),
            NavigationBar(
              selectedIndex: selectedIndex,
              backgroundColor: colors.surface,
              indicatorColor: colors.primaryContainer,
              // A translucent indicator over a card-coloured bar reads as a
              // tint; the full radius keeps it consistent with the card scale.
              indicatorShape: const RoundedRectangleBorder(
                borderRadius: AppRadius.pillAll,
              ),
              onDestinationSelected: select,
              destinations: [
                for (final tab in tabs)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.label,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // The rail is full-height: keep it clear of the status bar and the
          // gesture strip. The row follows Directionality, so in Arabic the
          // rail sits on the right without a second branch.
          SafeArea(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              backgroundColor: colors.surface,
              indicatorColor: colors.primaryContainer,
              destinations: [
                for (final tab in tabs)
                  NavigationRailDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: Text(tab.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
      // Same slot semantics as the compact shell: the strip takes its own
      // height and the page never has to reserve space for it.
      bottomNavigationBar: const MiniPlayerBar(),
    );
  }
}
