part of 'settings_screen.dart';

/// The settings list: the three reminder switches, their times, the permission
/// hint, the reminder-health readout and the (host-composed) backup section.
class _SettingsList extends StatelessWidget {
  const _SettingsList({
    required this.prayerEnabled,
    required this.azkarEnabled,
    required this.azkarTimeHm,
    required this.wirdEnabled,
    required this.wirdTimeHm,
    required this.permissionDenied,
    required this.adhanName,
    required this.backupSection,
    required this.locale,
    required this.theme,
    required this.skin,
    required this.reminderDiagnostics,
    required this.reminderApplyHealth,
  });

  final bool prayerEnabled;
  final bool azkarEnabled;
  final String azkarTimeHm;
  final bool wirdEnabled;
  final String wirdTimeHm;
  final bool permissionDenied;
  final String adhanName;
  final Widget? backupSection;
  final AppLocaleController? locale;
  final AppThemeController? theme;
  final PrayerSkinController? skin;
  final ReminderDiagnostics? reminderDiagnostics;
  final ReminderApplyHealth? reminderApplyHealth;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    final language = locale;
    final appearance = theme;
    return ListView(
      padding: EdgeInsets.only(bottom: appBottomInset(context)),
      children: [
        if (language != null) ...[
          ListenableBuilder(
            listenable: language,
            builder: (context, _) => ListTile(
              leading: const Icon(Icons.language),
              title: Text(loc.language),
              subtitle: Text(_languageLabel(loc, language.language)),
              onTap: () => unawaited(_pickLanguage(context, loc, language)),
            ),
          ),
          const Divider(height: 1),
        ],
        if (appearance != null) ...[
          ListenableBuilder(
            listenable: appearance,
            builder: (context, _) => ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: Text(loc.settingsTheme),
              subtitle: Text(_themeLabel(loc, appearance.mode)),
              onTap: () => unawaited(_pickTheme(context, loc, appearance)),
            ),
          ),
          const Divider(height: 1),
        ],
        if (skin case final skin?) ...[
          ListenableBuilder(
            listenable: skin,
            builder: (context, _) => ListTile(
              // Sits right under the appearance row: the skin recolours the
              // chrome, it does not change the light/dark choice.
              leading: const Icon(Icons.palette_outlined),
              title: Text(loc.settingsPrayerSkin),
              subtitle: Text(_prayerSkinLabel(loc, skin.mode)),
              onTap: () => unawaited(_pickPrayerSkin(context, loc, skin)),
            ),
          ),
          const Divider(height: 1),
        ],
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(loc.settingsPrayerReminder),
          value: prayerEnabled,
          onChanged: (value) => cubit.setPrayerEnabled(value),
        ),
        ListTile(
          leading: const Icon(Icons.music_note_outlined),
          title: Text(loc.adhanTitle),
          subtitle: Text(adhanName),
          onTap: () async {
            await context.push(AppRoutes.adhanPicker);
            // The picker owns the write, so re-read on return; otherwise the
            // subtitle would keep showing the reciter the user just replaced.
            await cubit.load();
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(loc.azkarReminder),
          value: azkarEnabled,
          onChanged: (value) => cubit.setAzkarEnabled(value),
        ),
        _ReminderTimeTile(
          enabled: azkarEnabled,
          title: loc.reminderTime,
          hm: azkarTimeHm,
          fallback: _parseHm(defaultAzkarTimeHm)!,
          onPicked: cubit.setTime,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(loc.settingsWirdReminder),
          value: wirdEnabled,
          onChanged: (value) => cubit.toggleWird(value),
        ),
        _ReminderTimeTile(
          enabled: wirdEnabled,
          title: loc.settingsWirdReminderTime,
          hm: wirdTimeHm,
          fallback: _parseHm(defaultWirdTimeHm)!,
          onPicked: cubit.changeWirdTime,
        ),
        if (permissionDenied)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
            child: Text(
              loc.notificationsEnabledHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        _reminderReliabilitySection(),
        if (backupSection case final section?) section,
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(loc.licensesTitle),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const LicensesScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: Text(loc.principlesTitle),
          onTap: () => context.push(AppRoutes.principles),
        ),
        const Divider(),
        // The note explains the SYSTEM default; once the user picks an
        // appearance the picker above is the single truth.
        if (appearance == null)
          _minimalNote(context, loc)
        else
          ListenableBuilder(
            listenable: appearance,
            builder: (context, _) => appearance.mode == AppThemeMode.system
                ? _minimalNote(context, loc)
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _minimalNote(BuildContext context, AppLocalizations loc) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          loc.settingsMinimalNote,
          style: AppTheme.mutedFootnote(context),
        ),
      );

  /// The reminder-health readout, or an empty box when this host has none:
  /// the service locator registration, or the diagnostics a host passes in.
  ///
  /// Android-only: every check behind the port is an Android OS capability
  /// (notification-alert permission, exact alarms, battery optimisation). On
  /// any other platform the channel answers "cannot report", which the section
  /// would render as a permanent «تعذّر الفحص» row naming a remedy that does
  /// not exist there — so the section stays out instead (an unreadable read on
  /// Android is still a real OEM gap and keeps its instruction row).
  ///
  /// A missing dependency is a normal state too (the frozen widget test builds
  /// `const SettingsScreen()` with only a cubit provider), so nothing here may
  /// throw and nothing may look broken.
  Widget _reminderReliabilitySection() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }
    final diagnostics = reminderDiagnostics;
    if (diagnostics == null) return const SizedBox.shrink();
    return _ReminderReliabilitySection(
      diagnostics: diagnostics,
      applyHealth: reminderApplyHealth,
    );
  }
}
