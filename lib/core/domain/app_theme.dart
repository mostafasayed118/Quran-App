/// The appearance choices the app ships.
///
/// `system` is the default and the pre-feature behaviour: the OS decides. The
/// values are the persisted identifiers, so an unknown stored name falls back
/// to [system] instead of leaving the app without a theme.
enum AppThemeMode {
  /// Follow the device's light/dark setting.
  system('system'),

  /// Always light.
  light('light'),

  /// Always dark.
  dark('dark');

  const AppThemeMode(this.code);

  /// The persisted identifier.
  final String code;

  /// The mode for a persisted [code]; unknown or missing falls back to
  /// [system].
  static AppThemeMode fromCode(String? code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return system;
  }
}

/// Storage seam for the appearance preference.
///
/// Deliberately outside the backup whitelist, like the language: the theme is a
/// per-device display choice, and a restore onto another phone must not flip
/// that phone's look.
abstract interface class AppThemeSource {
  /// The saved mode, or [AppThemeMode.system] when nothing usable is stored.
  Future<AppThemeMode> load();

  /// Persists [mode].
  Future<void> save(AppThemeMode mode);
}
