import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/error_pane.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.backupSection});

  /// Backup & restore surface, composed by the app shell (router) so this
  /// feature stays free of cross-feature imports (architecture guard).
  final Widget? backupSection;

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
            :final azkarEnabled,
            :final azkarTimeHm,
            :final wirdEnabled,
            :final wirdTimeHm,
            :final permissionDenied,
          ) =>
            _SettingsList(
              azkarEnabled: azkarEnabled,
              azkarTimeHm: azkarTimeHm,
              wirdEnabled: wirdEnabled,
              wirdTimeHm: wirdTimeHm,
              permissionDenied: permissionDenied,
              backupSection: backupSection,
            ),
        },
      ),
    );
  }
}

/// The settings list: the two reminder switches, their times, the permission
/// hint and the (host-composed) backup section.
class _SettingsList extends StatelessWidget {
  const _SettingsList({
    required this.azkarEnabled,
    required this.azkarTimeHm,
    required this.wirdEnabled,
    required this.wirdTimeHm,
    required this.permissionDenied,
    required this.backupSection,
  });

  final bool azkarEnabled;
  final String azkarTimeHm;
  final bool wirdEnabled;
  final String wirdTimeHm;
  final bool permissionDenied;
  final Widget? backupSection;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cubit = context.read<SettingsCubit>();
    return ListView(
      children: [
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
          fallback: const TimeOfDay(hour: 6, minute: 30),
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
          fallback: const TimeOfDay(hour: 20, minute: 0),
          onPicked: cubit.changeWirdTime,
        ),
        if (permissionDenied)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
            child: Text(
              loc.notificationsEnabledHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        if (backupSection != null) backupSection!,
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
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
