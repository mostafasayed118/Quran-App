part of 'settings_screen.dart';

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
      appLog(
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
