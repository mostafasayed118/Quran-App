import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/prayer_config.dart';
import '../../../../core/domain/prayer_name.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import 'prayer_config_cubit.dart';
import 'prayer_config_state.dart';

/// Lets the user choose the calculation method and the Asr madhab.
///
/// Every tap persists immediately; the prayer and home cubits listen to the
/// config stream and reload when the save lands.
class PrayerConfigScreen extends StatelessWidget {
  /// Creates the screen.
  const PrayerConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.prayerSettings)),
      body: BlocBuilder<PrayerConfigCubit, PrayerConfigState>(
        builder: (context, state) => switch (state) {
          PrayerConfigLoading() => const LoadingView(),
          PrayerConfigFailed() => errorPane(
              loc,
              onRetry: () => context.read<PrayerConfigCubit>().start(),
            ),
          PrayerConfigReady(:final config) => _Ready(config: config, loc: loc),
        },
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.config, required this.loc});

  final PrayerConfig config;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerConfigCubit>();
    return ListView(
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xl + appBottomInset(context),
      ),
      children: [
        _SectionLabel(loc.prayerCalcMethod),
        for (final method in PrayerCalculationMethod.values)
          _ChoiceTile(
            label: _methodLabel(loc, method),
            selected: config.method == method,
            onTap: () => cubit.setMethod(method),
          ),
        const Divider(height: AppSpacing.xl),
        _SectionLabel(loc.prayerMadhab),
        for (final madhab in PrayerMadhab.values)
          _ChoiceTile(
            label: _madhabLabel(loc, madhab),
            selected: config.madhab == madhab,
            onTap: () => cubit.setMadhab(madhab),
          ),
        const Divider(height: AppSpacing.xl),
        _SectionLabel(loc.prayerReminderPerPrayer),
        for (final prayer in PrayerName.values)
          if (prayer != PrayerName.sunrise)
            SwitchListTile(
              title: Text(prayer.label(loc)),
              value: config.enabledPrayers.contains(prayer),
              onChanged: (enabled) => cubit.setPrayerEnabled(prayer, enabled),
            ),
        const Divider(height: AppSpacing.xl),
        _SectionLabel(loc.preAdhanReminder),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _PreAdhanChip(
                label: loc.preAdhanOff,
                selected: config.preAdhanMinutes == 0,
                onTap: () => cubit.setPreAdhanMinutes(0),
              ),
              _PreAdhanChip(
                label: loc.preAdhanFive,
                selected: config.preAdhanMinutes == 5,
                onTap: () => cubit.setPreAdhanMinutes(5),
              ),
              _PreAdhanChip(
                label: loc.preAdhanTen,
                selected: config.preAdhanMinutes == 10,
                onTap: () => cubit.setPreAdhanMinutes(10),
              ),
              _PreAdhanChip(
                label: loc.preAdhanFifteen,
                selected: config.preAdhanMinutes == 15,
                onTap: () => cubit.setPreAdhanMinutes(15),
              ),
            ],
          ),
        ),
        const Divider(height: AppSpacing.xl),
        _SectionLabel(loc.prayerTuning),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            loc.prayerHighLatitude,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final rule in PrayerHighLatitudeRule.values)
                ChoiceChip(
                  label: Text(_highLatitudeLabel(loc, rule)),
                  selected: config.highLatitude == rule,
                  onSelected: (_) => cubit.setHighLatitude(rule),
                ),
            ],
          ),
        ),
        for (final prayer in PrayerName.values)
          if (prayer != PrayerName.sunrise)
            _AdjustmentRow(
              label: prayer.label(loc),
              minutes: config.adjustmentFor(prayer),
              onChanged: (value) => cubit.setAdjustment(prayer, value),
            ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Text(
            loc.prayerAdjustmentHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: Text(loc.monthlyTimetable),
          onTap: () => context.push(AppRoutes.prayerMonth),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Text(
            loc.prayerConfigNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.alarm_outlined),
          title: Text(loc.fajrFollowUp),
          subtitle: Text(loc.fajrFollowUpHint),
          value: config.fajrFollowUp,
          onChanged: (value) => cubit.setFajrFollowUp(value),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      selected: selected,
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _PreAdhanChip extends StatelessWidget {
  const _PreAdhanChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

String _methodLabel(AppLocalizations loc, PrayerCalculationMethod method) {
  return switch (method) {
    PrayerCalculationMethod.egyptian => loc.methodEgyptian,
    PrayerCalculationMethod.muslimWorldLeague => loc.methodMuslimWorldLeague,
    PrayerCalculationMethod.karachi => loc.methodKarachi,
    PrayerCalculationMethod.ummAlQura => loc.methodUmmAlQura,
    PrayerCalculationMethod.dubai => loc.methodDubai,
    PrayerCalculationMethod.kuwait => loc.methodKuwait,
    PrayerCalculationMethod.qatar => loc.methodQatar,
    PrayerCalculationMethod.turkey => loc.methodTurkey,
    PrayerCalculationMethod.northAmerica => loc.methodNorthAmerica,
  };
}

String _madhabLabel(AppLocalizations loc, PrayerMadhab madhab) {
  return switch (madhab) {
    PrayerMadhab.shafi => loc.madhabShafi,
    PrayerMadhab.hanafi => loc.madhabHanafi,
  };
}

String _highLatitudeLabel(
  AppLocalizations loc,
  PrayerHighLatitudeRule rule,
) {
  return switch (rule) {
    PrayerHighLatitudeRule.none => loc.highLatitudeNone,
    PrayerHighLatitudeRule.middleOfTheNight => loc.highLatitudeMiddle,
    PrayerHighLatitudeRule.seventhOfTheNight => loc.highLatitudeSeventh,
    PrayerHighLatitudeRule.twilightAngle => loc.highLatitudeTwilight,
  };
}

class _AdjustmentRow extends StatelessWidget {
  const _AdjustmentRow({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final value = minutes > 0 ? '+${loc.number(minutes)}' : loc.number(minutes);
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: loc.prayerAdjustmentDecrease,
            onPressed: minutes <= PrayerConfig.minAdjustmentMinutes
                ? null
                : () => onChanged(minutes - 1),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 48,
            child: Text(value, textAlign: TextAlign.center),
          ),
          IconButton(
            tooltip: loc.prayerAdjustmentIncrease,
            onPressed: minutes >= PrayerConfig.maxAdjustmentMinutes
                ? null
                : () => onChanged(minutes + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
