/// The languages the app ships.
///
/// Arabic is the default and the only locale that ever existed before v1.1;
/// the EN layer is a full mirror of the AR template (`lib/l10n/app_en.arb`),
/// so switching is a preference, not a translation task.
enum AppLanguage {
  /// Right-to-left.
  arabic('ar'),

  /// Left-to-right.
  english('en');

  const AppLanguage(this.code);

  /// The persisted / platform code (`ar`, `en`).
  final String code;

  /// The language for a persisted [code]; unknown or missing falls back to
  /// Arabic, so an unreadable setting can never leave the app without a locale.
  static AppLanguage fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return arabic;
  }
}

/// Storage seam for the language preference.
///
/// Deliberately outside the backup whitelist: the language is a per-device
/// reading choice, and a restore onto somebody else's phone must not flip it.
abstract interface class AppLocaleSource {
  /// The saved language, or Arabic when nothing usable is stored.
  Future<AppLanguage> load();

  /// Persists [language].
  Future<void> save(AppLanguage language);
}
