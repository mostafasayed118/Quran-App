/// The five daily prayers plus sunrise (a time marker, not a prayer).
///
/// Lives in core/domain so core-level code (l10n labels) never depends on
/// a feature module.
enum PrayerName {
  /// The dawn prayer.
  fajr,

  /// Sunrise — a time marker, not a prayer (it is never the "next prayer").
  sunrise,

  /// The midday prayer.
  dhuhr,

  /// The afternoon prayer.
  asr,

  /// The sunset prayer.
  maghrib,

  /// The night prayer.
  isha,
}
