import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/prayer_config.dart';
import '../../../../core/theme/app_spacing.dart';
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
