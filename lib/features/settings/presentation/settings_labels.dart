part of 'settings_screen.dart';

/// The stored 'H:mm' value as a clock time; null when it is missing or malformed.
TimeOfDay? _parseHm(String hm) {
  final hm24 = parseHourMinute(hm);
  if (hm24 == null) return null;
  return TimeOfDay(hour: hm24.$1, minute: hm24.$2);
}

/// The clock value the shared formatter renders (the date part is unused).
DateTime _asDateTime(TimeOfDay time) =>
    DateTime(2000, 1, 1, time.hour, time.minute);

/// The label for the current language, in the current language.
String _languageLabel(AppLocalizations loc, AppLanguage language) =>
    language == AppLanguage.arabic ? loc.languageArabic : loc.languageEnglish;

/// The label for the current appearance, in the current language.
String _themeLabel(AppLocalizations loc, AppThemeMode mode) => switch (mode) {
      AppThemeMode.system => loc.themeSystem,
      AppThemeMode.light => loc.themeLight,
      AppThemeMode.dark => loc.themeDark,
    };

/// The label for the current prayer-skin choice.
///
/// Each label carries its own promise: `fixed` names the theme the user sees
/// today, `follow` says that only the colours move.
String _prayerSkinLabel(AppLocalizations loc, PrayerSkinMode mode) =>
    switch (mode) {
      PrayerSkinMode.fixed => loc.prayerSkinFixed,
      PrayerSkinMode.follow => loc.prayerSkinFollow,
    };

/// Offers the three appearance modes; the controller applies and persists the
/// pick, and the app root repaints immediately.
/// Shared radio-option dialog body for the single-choice settings pickers.
/// Returns the picked value, or null when the dialog was dismissed.
Future<T?> _pickFromList<T>({
  required BuildContext context,
  required String title,
  required List<T> values,
  required T current,
  required String Function(T value) label,
  required Future<void> Function(T value) apply,
}) async {
  final selected = await showDialog<T>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(title),
      children: [
        for (final value in values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(value),
            child: Row(
              children: [
                Icon(
                  current == value
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(label(value)),
              ],
            ),
          ),
      ],
    ),
  );
  if (selected == null) return null;
  await apply(selected);
  return selected;
}

Future<void> _pickTheme(
  BuildContext context,
  AppLocalizations loc,
  AppThemeController controller,
) async {
  await _pickFromList<AppThemeMode>(
    context: context,
    title: loc.settingsTheme,
    values: AppThemeMode.values,
    current: controller.mode,
    label: (mode) => _themeLabel(loc, mode),
    apply: controller.setMode,
  );
}

/// Offers `fixed` / `follow`; the choice applies immediately and persists.
Future<void> _pickPrayerSkin(
  BuildContext context,
  AppLocalizations loc,
  PrayerSkinController controller,
) async {
  await _pickFromList<PrayerSkinMode>(
    context: context,
    title: loc.settingsPrayerSkin,
    values: PrayerSkinMode.values,
    current: controller.mode,
    label: (mode) => _prayerSkinLabel(loc, mode),
    apply: controller.setMode,
  );
}

/// Offers the shipped languages; the controller applies and persists the pick.
Future<void> _pickLanguage(
  BuildContext context,
  AppLocalizations loc,
  AppLocaleController controller,
) async {
  final picked = await _pickFromList<AppLanguage>(
    context: context,
    title: loc.language,
    values: AppLanguage.values,
    current: controller.language,
    label: (language) => language == AppLanguage.arabic
        ? loc.languageArabic
        : loc.languageEnglish,
    apply: controller.setLanguage,
  );
  // The reminder copy is localized at schedule time: re-plan so a pending
  // notification does not keep yesterday's language in the shade.
  if (picked != null && context.mounted) {
    await context.read<SettingsCubit>().refreshReminders();
  }
}
