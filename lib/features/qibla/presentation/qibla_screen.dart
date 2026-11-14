import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/city.dart';
import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/app_content_frame.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
import '../../../../core/widgets/loading_and_error_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/heading_service.dart';
import 'qibla_cubit.dart';
import 'qibla_state.dart';

part 'qibla_dial.dart';
part 'qibla_dial_widget.dart';

/// Rebuild gate for the qibla body. Heading samples arrive per sensor event;
/// sub-degree jitter (same rounded heading) skips a rebuild, so the dial can
/// trail by less than 1° until the next crossing. Every other field change
/// rebuilds.
bool qiblaBodyShouldRebuild(QiblaState previous, QiblaState current) {
  if (previous.runtimeType != current.runtimeType) return true;
  return switch ((previous, current)) {
    (final QiblaReady a, final QiblaReady b) => a.city != b.city ||
        a.bearing != b.bearing ||
        a.compassUnavailable != b.compassUnavailable ||
        a.calibrationNeeded != b.calibrationNeeded ||
        a.heading?.round() != b.heading?.round(),
    (QiblaFailed(), QiblaFailed()) => false,
    (QiblaLoading(), QiblaLoading()) => false,
    _ => true,
  };
}

/// How close the housing must be before the dial reports the qibla as reached.
const double kQiblaToleranceDeg = 5;

/// Signed shortest turn from the phone's top to the qibla, in (-180, 180].
///
/// [dialAngleDeg] returns 0..360 for the arrow; comparing two values on that
/// circle needs the wrapped form, otherwise "5° to the left" reads as 355°.
double qiblaDeltaDeg(double bearingDeg, double headingDeg) {
  final dial = dialAngleDeg(bearingDeg, headingDeg);
  return dial > 180 ? dial - 360 : dial;
}

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final cubit = context.read<QiblaCubit>();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        cubit.pause();
      case AppLifecycleState.resumed:
        cubit.resume();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.qibla)),
      body: AppContentFrame.form(
        child: BlocBuilder<QiblaCubit, QiblaState>(
          buildWhen: qiblaBodyShouldRebuild,
          builder: (context, state) {
            if (state is QiblaLoading) return const LoadingView();
            if (state is QiblaFailed) {
              return errorPane(
                loc,
                onRetry: () => context.read<QiblaCubit>().reload(),
              );
            }
            final (
              :city,
              :bearing,
              :heading,
              :compassUnavailable,
              :calibrationNeeded,
            ) = switch (state) {
              QiblaReady() => (
                  city: state.city,
                  bearing: state.bearing,
                  heading: state.heading,
                  compassUnavailable: state.compassUnavailable,
                  calibrationNeeded: state.calibrationNeeded,
                ),
              QiblaLoading() => (
                  city: state.city,
                  bearing: state.bearing,
                  heading: state.heading,
                  compassUnavailable: state.compassUnavailable,
                  calibrationNeeded: state.calibrationNeeded,
                ),
              QiblaFailed() => (
                  city: null,
                  bearing: null,
                  heading: null,
                  compassUnavailable: false,
                  calibrationNeeded: false,
                ),
            };
            if (city == null || bearing == null) {
              return EmptyState(
                loc.noCity,
                icon: Icons.location_off_outlined,
                actionLabel: loc.selectCity,
                onAction: () async {
                  final selected =
                      await context.push<bool>(AppRoutes.cityPicker);
                  if (selected == true && context.mounted) {
                    await context.read<QiblaCubit>().reload();
                  }
                },
              );
            }
            final delta = qiblaDeltaDeg(bearing, heading ?? 0);
            final aligned =
                heading != null && delta.abs() <= kQiblaToleranceDeg;
            // The page is short enough to build eagerly: the degree label is
            // part of the same reading as the dial, and a lazy ListView could
            // leave it unbuilt at large text scales.
            return SingleChildScrollView(
              padding: appScrollPadding(
                  context, const EdgeInsets.all(AppSpacing.lg)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CityTile(title: cityDisplayName(city, loc.localeName)),
                  const SizedBox(height: AppSpacing.lg),
                  _Dial(
                    bearing: bearing,
                    heading: heading,
                    aligned: aligned,
                    cityName: cityDisplayName(city, loc.localeName),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (heading == null)
                    _CompassNote(
                      text: compassUnavailable
                          ? loc.compassStatic
                          : loc.compassLive,
                    )
                  else
                    _CompassNote(text: loc.compassLive),
                  const SizedBox(height: AppSpacing.sm),
                  if (heading != null && calibrationNeeded)
                    _CalibrationHint(text: loc.qiblaCalibrationHint),
                  if (heading != null && calibrationNeeded)
                    const SizedBox(height: AppSpacing.sm),
                  if (heading != null)
                    _AlignmentHint(delta: delta, aligned: aligned)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: AppSpacing.md),
                  _DegreesLabel(bearing: bearing),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
