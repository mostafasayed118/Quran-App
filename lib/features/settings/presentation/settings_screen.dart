import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/error_pane.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            ListView(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: Text(loc.azkarReminder),
                  value: azkarEnabled,
                  onChanged: (value) =>
                      context.read<SettingsCubit>().setAzkarEnabled(value),
                ),
                ListTile(
                  enabled: azkarEnabled,
                  leading: const Icon(Icons.schedule),
                  title: Text(loc.reminderTime),
                  trailing: Text(
                    azkarTimeHm.toArabicIndicDigits,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: azkarEnabled
                      ? () => _pickTime(context, azkarTimeHm)
                      : null,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: Text(loc.settingsWirdReminder),
                  value: wirdEnabled,
                  onChanged: (value) =>
                      context.read<SettingsCubit>().toggleWird(value),
                ),
                ListTile(
                  enabled: wirdEnabled,
                  leading: const Icon(Icons.schedule),
                  title: Text(loc.settingsWirdReminderTime),
                  trailing: Text(
                    wirdTimeHm.toArabicIndicDigits,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: wirdEnabled
                      ? () => _pickWirdTime(context, wirdTimeHm)
                      : null,
                ),
                if (permissionDenied)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      loc.notificationsEnabledHint,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc.settingsMinimalNote,
                    style: AppTheme.mutedFootnote(context),
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, String hm) async {
    final cubit = context.read<SettingsCubit>();
    final parts = hm.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 6,
      minute: int.tryParse(parts.length > 1 ? parts.last : '') ?? 30,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await cubit.setTime(
      '${picked.hour.toString().padLeft(2, '0')}:'
      '${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _pickWirdTime(BuildContext context, String hm) async {
    final cubit = context.read<SettingsCubit>();
    final parts = hm.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 20,
      minute: int.tryParse(parts.length > 1 ? parts.last : '') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await cubit.changeWirdTime(
      '${picked.hour.toString().padLeft(2, '0')}:'
      '${picked.minute.toString().padLeft(2, '0')}',
    );
  }
}
