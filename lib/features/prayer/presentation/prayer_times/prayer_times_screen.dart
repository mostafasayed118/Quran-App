import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/city.dart';
import '../../../../core/domain/prayer_name.dart';
import '../../../../core/l10n/prayer_names.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../l10n/app_localizations.dart';
import 'prayer_times_cubit.dart';
import 'prayer_times_state.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  /// W7b (W7a §6): reload in place when the picker returns a selection —
  /// the picker pops `true` on a successful persist; zero state change.
  static Future<void> _openCityPicker(BuildContext context) async {
    final cubit = context.read<PrayerTimesCubit>();
    final reloaded = await context.push<bool>(AppRoutes.cityPicker);
    if (reloaded == true && context.mounted) {
      await cubit.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.prayerTimes),
        actions: [
          IconButton(
            tooltip: loc.prayerSettings,
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => context.push(AppRoutes.prayerSettings),
          ),
          IconButton(
            tooltip: loc.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PrayerTimesCubit>().reload(),
          ),
        ],
      ),
      body: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
        builder: (context, state) => switch (state) {
          PrayerTimesLoading() => const LoadingView(),
          PrayerTimesFailed() => errorPane(
              loc,
              onRetry: () => context.read<PrayerTimesCubit>().reload(),
            ),
          PrayerTimesReady(:final city?) => RefreshIndicator(
              onRefresh: () => context.read<PrayerTimesCubit>().reload(),
              child: _TimesList(state: state, city: city),
            ),
          PrayerTimesReady() => EmptyState(
              loc.noCity,
              icon: Icons.location_off_outlined,
              actionLabel: loc.selectCity,
              onAction: () => _openCityPicker(context),
            ),
        },
      ),
    );
  }
}

class _TimesList extends StatefulWidget {
  const _TimesList({required this.state, required this.city});

  final PrayerTimesReady state;
  final City city;

  @override
  State<_TimesList> createState() => _TimesListState();
}

class _TimesListState extends State<_TimesList> with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  void _startTicker() {
    if (_ticker != null) return;
    final cubit = context.read<PrayerTimesCubit>();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      cubit.refreshCountdown();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _stopTicker();
      case AppLifecycleState.resumed:
        _startTicker();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = widget.state;
    final entries = state.entries;
    return ListView(
      padding: appScrollPadding(
        context,
        const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
        ),
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _CityCard(city: widget.city),
        const SizedBox(height: AppSpacing.md),
        // One panel, hairline-separated rows: seven separate elevated cards
        // made the list look like seven independent facts and pushed the last
        // prayer off screen.
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                _PrayerRow(
                  entry: entries[i],
                  remaining: state.remaining,
                  loc: loc,
                ),
                if (i != entries.length - 1)
                  const Divider(height: 1, indent: 14, endIndent: 14),
              ],
            ],
          ),
        ),
        if (state.nextTomorrowName != null &&
            state.nextTomorrowTime != null) ...[
          const SizedBox(height: AppSpacing.md),
          _TomorrowNote(
            name: state.nextTomorrowName!,
            time: state.nextTomorrowTime!,
            remaining: state.nextTomorrowRemaining,
          ),
        ],
      ],
    );
  }
}

/// What comes after today's last prayer.
///
/// Without it the panel went silent after Isha while Home advertised
/// tomorrow's Fajr — two screens disagreeing about the same fact.
class _TomorrowNote extends StatelessWidget {
  const _TomorrowNote({
    required this.name,
    required this.time,
    required this.remaining,
  });

  final PrayerName name;
  final DateTime time;
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nights_stay_outlined,
                size: 18,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.nextPrayerTomorrow(
                      name.label(loc),
                      formatHm(time, arabicIndic: loc.usesArabicIndicDigits),
                    ),
                    style: AppTheme.cardTitle.copyWith(fontSize: 15),
                  ),
                  if (remaining != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      loc.remaining(formatDurationHm(remaining!,
                          arabicIndic: loc.usesArabicIndicDigits)),
                      style: AppTheme.caption
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  const _CityCard({required this.city});

  final City city;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => PrayerTimesScreen._openCityPicker(context),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(city.nameAr, style: AppTheme.meQuranTitle),
              ),
              IconButton(
                tooltip: loc.selectCity,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => PrayerTimesScreen._openCityPicker(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the prayer panel.
///
/// The next prayer is the only row with a schedule glyph and a countdown, so
/// the highlight is carried by shape and content as well as colour. Sunrise is
/// a time marker, not a prayer, and is rendered muted with a sun glyph instead
/// of the radio-button dot it used to borrow.
class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.entry,
    required this.remaining,
    required this.loc,
  });

  final PrayerEntry entry;
  final Duration? remaining;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isNext = entry.isNext;
    final isSunrise = entry.name == PrayerName.sunrise;
    final foreground = isNext ? colors.onPrimaryContainer : colors.onSurface;
    final muted = isNext
        ? colors.onPrimaryContainer.withValues(alpha: 0.75)
        : colors.onSurfaceVariant;

    return Container(
      decoration: isNext
          ? BoxDecoration(
              color: colors.primaryContainer,
              border: BorderDirectional(
                start: BorderSide(color: colors.primary, width: 3),
              ),
            )
          : null,
      padding: EdgeInsetsDirectional.fromSTEB(
        isNext ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (isNext)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Icon(Icons.schedule, size: 20, color: foreground),
            )
          else if (isSunrise)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Icon(Icons.wb_sunny_outlined, size: 18, color: muted),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name.label(loc),
                  style: isNext
                      ? AppTheme.cardTitle.copyWith(color: foreground)
                      : AppTheme.rowTitle.copyWith(
                          color: isSunrise ? muted : foreground,
                          fontWeight: FontWeight.w400,
                        ),
                ),
                if (isNext && remaining != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    loc.remaining(formatDurationHm(remaining!,
                        arabicIndic: loc.usesArabicIndicDigits)),
                    style: AppTheme.caption.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatHm(entry.time, arabicIndic: loc.usesArabicIndicDigits),
            style: isNext
                ? AppTheme.cardTitle.copyWith(color: foreground)
                : AppTheme.rowTitle.copyWith(
                    color: isSunrise ? muted : foreground,
                    fontWeight: FontWeight.w400,
                  ),
          ),
        ],
      ),
    );
  }
}
