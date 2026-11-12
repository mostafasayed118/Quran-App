import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../core/domain/adhan_catalog.dart';
import '../../../core/domain/app_locale.dart';
import '../../../core/domain/app_theme.dart';
import '../../../core/domain/reminder_diagnostics.dart';
import '../../../core/domain/reminders.dart';
import '../../../core/l10n/app_locale_controller.dart';
import '../../../core/l10n/app_localizations_digits.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/utils/hour_minute.dart';
import '../../../core/utils/insets.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/error_pane.dart';
import '../../../core/widgets/loading_and_error_views.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import 'licenses_screen.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';

part 'settings_list.dart';
part 'settings_reminders.dart';
part 'settings_labels.dart';

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

  /// Reminder-health readout seam, passed by the host that owns the ports.
  /// Optional on purpose: the frozen settings test builds
  /// `const SettingsScreen()` with nothing but a cubit provider, and a missing
  /// readout must never break that screen.
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
            SettingsFailed() =>
              errorPane(loc, onRetry: context.read<SettingsCubit>().load),
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
                adhanName: locale?.language == AppLanguage.english
                    ? adhanById(adhanId).nameEn
                    : adhanById(adhanId).nameAr,
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
