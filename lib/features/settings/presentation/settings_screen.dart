import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/domain/app_locale.dart';
import '../../../core/domain/reminder_diagnostics.dart';
import '../../../core/domain/reminders.dart';
import '../../../core/l10n/app_locale_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/utils/insets.dart';
import '../../../core/widgets/loading_and_error_views.dart';
import '../../../core/widgets/error_pane.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';
import 'licenses_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.backupSection,
    this.locale,
    this.reminderDiagnostics,
  });

  /// Backup & restore surface, composed by the app shell (router) so this
  /// feature stays free of cross-feature imports (architecture guard).
  final Widget? backupSection;

  /// The language switch, wired by the composition root. Null keeps the row
  /// out (a host that does not opt in, e.g. a focused widget test).
  final AppLocaleController? locale;

  /// Reminder-health readout seam, resolved from the service locator when a
  /// host does not pass one. Optional twice over on purpose: the frozen
  /// settings test builds `const SettingsScreen()` with nothing but a cubit
  /// provider, and a missing readout must never break that screen.
  final ReminderDiagnostics? reminderDiagnostics;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
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
          ) =>
            _SettingsList(
              prayerEnabled: prayerEnabled,
              azkarEnabled: azkarEnabled,
              azkarTimeHm: azkarTimeHm,
              wirdEnabled: wirdEnabled,
              wirdTimeHm: wirdTimeHm,
              permissionDenied: azkarPermissionDenied || wirdPermissionDenied,
              backupSection: backupSection,
              locale: locale,
              reminderDiagnostics: reminderDiagnostics,
            ),
        },
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
    required this.backupSection,
    required this.locale,
    required this.reminderDiagnostics,
  });

  final bool prayerEnabled;
  final bool azkarEnabled;
  final String azkarTimeHm;
  final bool wirdEnabled;
  final String wirdTimeHm;
  final bool permissionDenied;
  final Widget? backupSection;
  final AppLocaleController? locale;
  final ReminderDiagnostics? reminderDiagnostics;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    final language = locale;
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
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(loc.settingsPrayerReminder),
          value: prayerEnabled,
          onChanged: (value) => cubit.setPrayerEnabled(value),
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

  /// The reminder-health readout, or an empty box when this host provides
  /// none: the constructor argument first, then the service locator.
  ///
  /// A missing dependency is a normal state (the frozen widget test builds
  /// `const SettingsScreen()` with only a cubit provider), so nothing here may
  /// throw and nothing may look broken — the section simply stays out.
  Widget _reminderReliabilitySection() {
    final diagnostics = reminderDiagnostics ??
        (GetIt.I.isRegistered<ReminderDiagnostics>()
            ? GetIt.I<ReminderDiagnostics>()
            : null);
    if (diagnostics == null) return const SizedBox.shrink();
    return _ReminderReliabilitySection(diagnostics: diagnostics);
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
  const _ReminderReliabilitySection({required this.diagnostics});

  final ReminderDiagnostics diagnostics;

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
    unawaited(_read());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_read());
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
        );
        _batteryUnknown = battery == null;
      });
    } on Object {
      return;
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
        SectionHeader(title: loc.reminderReliabilityTitle),
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
    return ListTile(
      enabled: enabled,
      leading: const Icon(Icons.schedule),
      title: Text(title),
      trailing: Text(
        formatHm(_asDateTime(_parseHm(hm) ?? fallback)),
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

/// Parses the stored 'HH:mm' value; null when it is missing or malformed.
TimeOfDay? _parseHm(String hm) {
  final parts = hm.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

/// The clock value the shared formatter renders (the date part is unused).
DateTime _asDateTime(TimeOfDay time) =>
    DateTime(2000, 1, 1, time.hour, time.minute);

/// The label for the current language, in the current language.
String _languageLabel(AppLocalizations loc, AppLanguage language) =>
    language == AppLanguage.arabic ? loc.languageArabic : loc.languageEnglish;

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
}
