import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/adhan_catalog.dart';
import '../../../core/domain/app_locale.dart';
import '../../../core/domain/app_theme.dart';
import '../../../core/domain/reminder_diagnostics.dart';
import '../../../core/domain/reminders.dart';
import '../../../core/l10n/app_locale_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/utils/hour_minute.dart';
import '../../../core/utils/insets.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/loading_and_error_views.dart';
import '../../../core/widgets/error_pane.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/l10n/app_localizations_digits.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';
import 'licenses_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.backupSection,
    this.locale,
    this.theme,
    this.reminderDiagnostics,
    this.reminderApplyHealth,
  });

  /// Backup & restore surface, composed by the app shell (router) so this
  /// feature stays free of cross-feature imports (architecture guard).
  final Widget? backupSection;

  /// The language switch, wired by the composition root. Null keeps the row
  /// out (a host that does not opt in, e.g. a focused widget test).
  final AppLocaleController? locale;

  /// The appearance switch, wired the same way. Null keeps its row out.
  final AppThemeController? theme;

  /// Reminder-health readout seam, resolved from the service locator when a
  /// host does not pass one. Optional twice over on purpose: the frozen
  /// settings test builds `const SettingsScreen()` with nothing but a cubit
  /// provider, and a missing readout must never break that screen.
  final ReminderDiagnostics? reminderDiagnostics;

  /// The last plan write's outcome (the binding owns it). Null keeps the
  /// schedule row out, like a missing diagnostics port.
  final ReminderApplyHealth? reminderApplyHealth;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: AppContentFrame(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => switch (state) {
            SettingsLoading() => const LoadingView(),
            SettingsFailed() => errorPane(loc),
            SettingsReady(
              :final prayerEnabled,
              :final azkarEnabled,
              :final azkarTimeHm,
              :final wirdEnabled,
              :final wirdTimeHm,
              :final azkarPermissionDenied,
              :final wirdPermissionDenied,
              :final adhanId,
            ) =>
              _SettingsList(
                prayerEnabled: prayerEnabled,
                azkarEnabled: azkarEnabled,
                azkarTimeHm: azkarTimeHm,
                wirdEnabled: wirdEnabled,
                wirdTimeHm: wirdTimeHm,
                permissionDenied: azkarPermissionDenied || wirdPermissionDenied,
                adhanNameAr: adhanById(adhanId).nameAr,
                backupSection: backupSection,
                locale: locale,
                theme: theme,
                reminderDiagnostics: reminderDiagnostics,
                reminderApplyHealth: reminderApplyHealth,
              ),
          },
        ),
      ),
    );
  }
}

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
    required this.adhanNameAr,
    required this.backupSection,
    required this.locale,
    required this.theme,
    required this.reminderDiagnostics,
    required this.reminderApplyHealth,
  });

  final bool prayerEnabled;
  final bool azkarEnabled;
  final String azkarTimeHm;
  final bool wirdEnabled;
  final String wirdTimeHm;
  final bool permissionDenied;
  final String adhanNameAr;
  final Widget? backupSection;
  final AppLocaleController? locale;
  final AppThemeController? theme;
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
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(loc.settingsPrayerReminder),
          value: prayerEnabled,
          onChanged: (value) => cubit.setPrayerEnabled(value),
        ),
        ListTile(
          leading: const Icon(Icons.music_note_outlined),
          title: Text(loc.adhanTitle),
          subtitle: Text(adhanNameAr),
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
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            loc.settingsMinimalNote,
            style: AppTheme.mutedFootnote(context),
          ),
        ),
      ],
    );
  }

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
    final diagnostics = reminderDiagnostics ??
        (GetIt.I.isRegistered<ReminderDiagnostics>()
            ? GetIt.I<ReminderDiagnostics>()
            : null);
    if (diagnostics == null) return const SizedBox.shrink();
    final applyHealth = reminderApplyHealth ??
        (GetIt.I.isRegistered<ReminderApplyHealth>()
            ? GetIt.I<ReminderApplyHealth>()
            : null);
    return _ReminderReliabilitySection(
      diagnostics: diagnostics,
      applyHealth: applyHealth,
    );
  }
}

/// The «موثوقية التذكيرات» readout: one row per reason the OS may suppress a
/// prayer/azkar reminder, each carrying the system screen that fixes it.
///
/// Reads on mount and again on every resume — Android 14 lets the user revoke
/// exact alarms from the system settings, so a cached boot-time verdict would
/// be wrong exactly when it matters. A healthy device sees no section at all;
/// an unreadable battery state shows the "check it yourself" instruction
/// instead of a verdict the device never produced.
class _ReminderReliabilitySection extends StatefulWidget {
  const _ReminderReliabilitySection({
    required this.diagnostics,
    this.applyHealth,
  });

  final ReminderDiagnostics diagnostics;
  final ReminderApplyHealth? applyHealth;

  @override
  State<_ReminderReliabilitySection> createState() =>
      _ReminderReliabilitySectionState();
}

class _ReminderReliabilitySectionState
    extends State<_ReminderReliabilitySection> with WidgetsBindingObserver {
  List<ReminderIssue> _issues = const <ReminderIssue>[];
  bool _batteryUnknown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.applyHealth?.addListener(_onApplyHealthChanged);
    unawaited(_read());
  }

  @override
  void didUpdateWidget(covariant _ReminderReliabilitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.applyHealth, widget.applyHealth)) return;
    oldWidget.applyHealth?.removeListener(_onApplyHealthChanged);
    widget.applyHealth?.addListener(_onApplyHealthChanged);
    unawaited(_read());
  }

  @override
  void dispose() {
    widget.applyHealth?.removeListener(_onApplyHealthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_read());
  }

  /// A schedule can fail while this screen is mounted (the user changed a
  /// reminder time); re-read on the binding's notification instead of waiting
  /// for the next resume.
  void _onApplyHealthChanged() {
    if (mounted) unawaited(_read());
  }

  /// Advisory readout: an unreadable state keeps the last verdict instead of
  /// taking the settings screen down.
  Future<void> _read() async {
    try {
      final notifications = await widget.diagnostics.notificationsEnabled();
      final exactAlarms = await widget.diagnostics.exactAlarmsAllowed();
      final battery = await widget.diagnostics.batteryOptimizationIgnored();
      if (!mounted) return;
      setState(() {
        _issues = diagnoseReminders(
          notificationsEnabled: notifications,
          exactAlarmsAllowed: exactAlarms,
          batteryOptimizationIgnored: battery,
          scheduleFailed: widget.applyHealth?.lastApplyFailed ?? false,
        );
        _batteryUnknown = battery == null;
      });
    } on Object catch (error, stackTrace) {
      dev.log(
        'settings reminder diagnostics read failed',
        name: 'quran_yahdi/settings',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final batteryUnknown = _batteryUnknown;
    if (_issues.isEmpty && !batteryUnknown) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: loc.reminderReliabilityTitle,
          inset: AppSpacing.lg,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          child: Text(
            loc.reminderReliabilityIntro,
            style: AppTheme.mutedFootnote(context),
          ),
        ),
        for (final issue in _issues) _issueTile(loc, issue),
        if (batteryUnknown)
          ListTile(
            leading: const Icon(Icons.battery_unknown_outlined),
            title: Text(loc.reminderIssueBatteryUnknown),
          ),
      ],
    );
  }

  /// One issue row: the platform screen that fixes it is the trailing action.
  ///
  /// The notification permission has no such screen in the port (the copy
  /// already says where to grant it), so that row carries no action rather
  /// than a button that cannot do anything.
  Widget _issueTile(AppLocalizations loc, ReminderIssue issue) {
    final (IconData icon, String message, Future<bool> Function()? onFix) =
        switch (issue) {
      ReminderIssue.notificationsOff => (
          Icons.notifications_off_outlined,
          loc.reminderIssueNotifications,
          null,
        ),
      ReminderIssue.exactAlarmsOff => (
          Icons.alarm_off_outlined,
          loc.reminderIssueExactAlarms,
          widget.diagnostics.openExactAlarmSettings,
        ),
      ReminderIssue.batteryRestricted => (
          Icons.battery_alert_outlined,
          loc.reminderIssueBattery,
          widget.diagnostics.openBatteryOptimizationSettings,
        ),
      // No system screen fixes this one: the next boot/resume retries the
      // write, so the row is the honest report, not a dead button.
      ReminderIssue.scheduleFailed => (
          Icons.event_busy_outlined,
          loc.reminderIssueScheduleFailed,
          null,
        ),
    };
    return ListTile(
      leading: Icon(icon),
      title: Text(message),
      // Best-effort: the port reports false instead of throwing, and the
      // resume re-read picks the change up when the user comes back.
      trailing: onFix == null
          ? null
          : TextButton(
              onPressed: () => onFix().ignore(),
              child: Text(loc.reminderFixAction),
            ),
    );
  }
}

/// One reminder-time row: shows the stored 'HH:mm' value (Arabic-Indic) and
/// opens the material time picker when the reminder is enabled.
///
/// The picked value is handed back in the PERSISTED format ('HH:mm', the
/// form the reminder planner parses) — the rendered label is the Arabic-Indic
/// one the shared [formatHm] produces.
class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({
    required this.enabled,
    required this.title,
    required this.hm,
    required this.fallback,
    required this.onPicked,
  });

  final bool enabled;
  final String title;
  final String hm;
  final TimeOfDay fallback;
  final Future<void> Function(String hm) onPicked;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListTile(
      enabled: enabled,
      leading: const Icon(Icons.schedule),
      title: Text(title),
      trailing: Text(
        formatHm(
          _asDateTime(_parseHm(hm) ?? fallback),
          arabicIndic: loc.usesArabicIndicDigits,
        ),
        style: AppTheme.rowTitle,
      ),
      onTap: enabled ? () => _pick(context) : null,
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseHm(hm) ?? fallback,
    );
    if (picked == null) return;
    await onPicked(formatHm(_asDateTime(picked), arabicIndic: false));
  }
}

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

/// Offers the three appearance modes; the controller applies and persists the
/// pick, and the app root repaints immediately.
Future<void> _pickTheme(
  BuildContext context,
  AppLocalizations loc,
  AppThemeController controller,
) async {
  final selected = await showDialog<AppThemeMode>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(loc.settingsTheme),
      children: [
        for (final mode in AppThemeMode.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(mode),
            child: Row(
              children: [
                Icon(
                  controller.mode == mode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(_themeLabel(loc, mode)),
              ],
            ),
          ),
      ],
    ),
  );
  if (selected == null) return;
  await controller.setMode(selected);
}

/// Offers the shipped languages; the controller applies and persists the pick.
Future<void> _pickLanguage(
  BuildContext context,
  AppLocalizations loc,
  AppLocaleController controller,
) async {
  final selected = await showDialog<AppLanguage>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(loc.language),
      children: [
        for (final language in AppLanguage.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(language),
            child: Row(
              children: [
                Icon(
                  controller.language == language
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  language == AppLanguage.arabic
                      ? loc.languageArabic
                      : loc.languageEnglish,
                ),
              ],
            ),
          ),
      ],
    ),
  );
  if (selected == null) return;
  await controller.setLanguage(selected);
  // The reminder copy is localized at schedule time: re-plan so a pending
  // notification does not keep yesterday's language in the shade.
  if (context.mounted) await context.read<SettingsCubit>().refreshReminders();
}
