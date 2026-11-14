/// The prayer-skin choices the app ships.
///
/// [fixed] is the default and the pre-feature behaviour: the chrome keeps the
/// shipped emerald/gold theme. [follow] changes **only the colours** of the
/// chrome to the current period's palette — no layout, no reader, no behaviour.
///
/// The values are the persisted identifiers, so an unknown stored name falls
/// back to [fixed] instead of leaving the app without a theme.
enum PrayerSkinMode {
  /// The shipped theme, always.
  fixed('fixed'),

  /// The chrome follows the current prayer period.
  follow('follow');

  const PrayerSkinMode(this.code);

  /// The persisted identifier.
  final String code;

  /// The mode for a persisted [code]; unknown or missing falls back to
  /// [fixed].
  static PrayerSkinMode fromCode(String? code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return fixed;
  }
}

/// Storage seam for the prayer-skin preference.
///
/// Deliberately outside the backup whitelist, like the appearance and the
/// language: a per-device display choice that a restore must not flip.
abstract interface class PrayerSkinSource {
  /// The saved mode, or [PrayerSkinMode.fixed] when nothing usable is stored.
  Future<PrayerSkinMode> load();

  /// Persists [mode].
  Future<void> save(PrayerSkinMode mode);
}
