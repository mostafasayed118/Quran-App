part of 'home_screen.dart';

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.services});

  final List<_Service> services;

  /// Three columns, chunked into rows.
  ///
  /// A `Wrap` lets every tile size itself, which leaves the short labels
  /// floating above the baseline of the long ones. `IntrinsicHeight` gives
  /// each row one height, so the tile bottoms line up without capping the
  /// label (the old grid capped it with `maxLines: 2` + ellipsis).
  @override
  Widget build(BuildContext context) {
    const gap = AppSpacing.sm;
    final loc = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns on a 320 dp phone keep the label readable; three from
        // 340 dp up. The width comes from the frame, not MediaQuery, because
        // a tablet renders this grid inside a capped column.
        final columns = constraints.maxWidth < 340 ? 2 : 3;
        final rows = <List<_Service>>[
          for (var i = 0; i < services.length; i += columns)
            services.sublist(
              i,
              i + columns > services.length ? services.length : i + columns,
            ),
        ];
        return Column(
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: gap),
                      if (c < rows[r].length)
                        Expanded(
                          child: ServiceTile(
                            icon: rows[r][c].icon,
                            label: rows[r][c].label(loc),
                            onTap: () => context.push(rows[r][c].route),
                          ),
                        )
                      else
                        const Spacer(),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

typedef _Service = ({
  IconData icon,
  String Function(AppLocalizations) label,
  String route
});

const List<_Service> _quranServices = [
  (icon: Icons.menu_book, label: _locQuran, route: AppRoutes.quran),
  (icon: Icons.graphic_eq, label: _locRecitations, route: AppRoutes.recitation),
  (
    icon: Icons.bookmarks_outlined,
    label: _locBookmarks,
    route: AppRoutes.bookmarks
  ),
];

const List<_Service> _worshipServices = [
  (icon: Icons.schedule, label: _locPrayerTimes, route: AppRoutes.prayerTimes),
  (icon: Icons.explore, label: _locQibla, route: AppRoutes.qibla),
  (icon: Icons.spa, label: _locAzkar, route: AppRoutes.azkar),
  (
    icon: Icons.radio_button_checked,
    label: _locTasbih,
    route: AppRoutes.tasbih
  ),
  (icon: Icons.volunteer_activism, label: _locDuas, route: AppRoutes.duas),
  (icon: Icons.mosque, label: _locWorship, route: AppRoutes.worship),
  (icon: Icons.nightlight_round, label: _locRamadan, route: AppRoutes.ramadan),
];

const List<_Service> _moreServices = [
  (icon: Icons.library_books, label: _locLibrary, route: AppRoutes.library),
  (icon: Icons.payments_outlined, label: _locZakat, route: AppRoutes.zakat),
  (icon: Icons.calendar_month, label: _locHijri, route: AppRoutes.hijri),
  (icon: Icons.auto_awesome, label: _locAsma, route: AppRoutes.asma),
  (icon: Icons.settings, label: _locSettings, route: AppRoutes.settings),
];

String _locQuran(AppLocalizations loc) => loc.quran;
String _locPrayerTimes(AppLocalizations loc) => loc.prayerTimes;
String _locQibla(AppLocalizations loc) => loc.qibla;
String _locRecitations(AppLocalizations loc) => loc.recitations;
String _locLibrary(AppLocalizations loc) => loc.library;
String _locAzkar(AppLocalizations loc) => loc.azkar;
String _locTasbih(AppLocalizations loc) => loc.tasbih;
String _locDuas(AppLocalizations loc) => loc.duasAndRuqyah;
String _locWorship(AppLocalizations loc) => loc.worshipTracker;
String _locRamadan(AppLocalizations loc) => loc.ramadanTitle;
String _locZakat(AppLocalizations loc) => loc.zakat;
String _locHijri(AppLocalizations loc) => loc.hijriCalendar;
String _locAsma(AppLocalizations loc) => loc.asmaUlHusna;

String _locBookmarks(AppLocalizations loc) => loc.bookmarks;

String _locSettings(AppLocalizations loc) => loc.settings;
