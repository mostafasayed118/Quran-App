import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations_digits.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
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
                  _CityTile(title: city.nameAr),
                  const SizedBox(height: AppSpacing.lg),
                  _Dial(
                    bearing: bearing,
                    heading: heading,
                    aligned: aligned,
                    cityName: city.nameAr,
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

/// Ring, ticks, cardinal letters and the qibla marker.
///
/// The letters and the marker rotate with the live heading so the dial answers
/// "where is north from here?" and not just "which way is up". Without them
/// the ring was decoration and the only reference was the arrow itself.
class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.colors,
    required this.heading,
    required this.bearing,
    required this.aligned,
    required this.cardinalNorth,
    required this.cardinalEast,
    required this.cardinalSouth,
    required this.cardinalWest,
    required this.direction,
  });

  final ColorScheme colors;
  final double heading;
  final double bearing;
  final bool aligned;

  /// Full words, not initials: Arabic شمال and شرق share the same first
  /// letter, so an initial-only dial would print ش twice. The four labels
  /// come from the catalogue so the dial follows the app language.
  final String cardinalNorth;
  final String cardinalEast;
  final String cardinalSouth;
  final String cardinalWest;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - AppSpacing.sm;

    final ringColor = aligned ? colors.secondary : colors.outline;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 3 : 2
        ..color = ringColor,
    );

    for (var i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180.0;
      final isMajor = i % 90 == 0;
      final p1 = Offset(
        center.dx + (radius - (isMajor ? 14 : 10)) * math.sin(angle),
        center.dy - (radius - (isMajor ? 14 : 10)) * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = isMajor ? 3 : 1
          ..color = isMajor ? colors.primary : colors.outline,
      );
    }

    // Cardinal letters sit at their true bearing, which is fixed on the dial
    // and moves on screen as the device turns.
    final cardinals = <(double, String)>[
      (0, cardinalNorth),
      (90, cardinalEast),
      (180, cardinalSouth),
      (270, cardinalWest),
    ];
    for (final entry in cardinals) {
      final angle = (entry.$1 - heading) * math.pi / 180.0;
      final labelRadius = radius - 30;
      final offset = Offset(
        center.dx + labelRadius * math.sin(angle),
        center.dy - labelRadius * math.cos(angle),
      );
      final painter = TextPainter(
        text: TextSpan(
          text: entry.$2,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: entry.$1 == 0 ? colors.primary : colors.onSurfaceVariant,
            fontFamily: AppTheme.sectionLabel.fontFamily,
          ),
        ),
        textDirection: direction,
      )..layout();
      painter.paint(
        canvas,
        offset - Offset(painter.width / 2, painter.height / 2),
      );
    }

    // Qibla marker on the rim.
    final qiblaAngle = (bearing - heading) * math.pi / 180.0;
    final marker = Offset(
      center.dx + radius * math.sin(qiblaAngle),
      center.dy - radius * math.cos(qiblaAngle),
    );
    canvas.drawCircle(marker, 9, Paint()..color = colors.secondary);
    canvas.drawCircle(
      marker,
      4,
      Paint()..color = colors.surface,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.heading.round() != heading.round() ||
      oldDelegate.bearing != bearing ||
      oldDelegate.aligned != aligned ||
      oldDelegate.cardinalNorth != cardinalNorth ||
      oldDelegate.cardinalEast != cardinalEast ||
      oldDelegate.cardinalSouth != cardinalSouth ||
      oldDelegate.cardinalWest != cardinalWest ||
      oldDelegate.direction != direction;
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 18, color: colors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: AppTheme.meQuranTitle,
          ),
        ),
      ],
    );
  }
}

class _CompassNote extends StatelessWidget {
  const _CompassNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: AppTheme.mutedFootnote(context)),
    );
  }
}

/// Shown when the raw field is disturbed or the phone is near-vertical.
class _CalibrationHint extends StatelessWidget {
  const _CalibrationHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.35),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(Icons.explore_off_outlined, size: 18, color: colors.error),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Turn left/right N°" until the housing lines up, or the aligned state.
class _AlignmentHint extends StatelessWidget {
  const _AlignmentHint({required this.delta, required this.aligned});

  final double delta;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (aligned) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.14),
            borderRadius: AppRadius.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  size: 18, color: AppTheme.goldText(context)),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  loc.qiblaAligned,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.goldText(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final degrees = delta.abs().round();
    if (degrees == 0) return const SizedBox.shrink();
    return Center(
      child: Text(
        delta > 0
            ? loc.qiblaTurnRight(loc.number(degrees))
            : loc.qiblaTurnLeft(loc.number(degrees)),
        style: AppTheme.caption.copyWith(color: colors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DegreesLabel extends StatelessWidget {
  const _DegreesLabel({required this.bearing});

  final double bearing;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Text(
        loc.degreesFromNorth(loc.number(bearing.round())),
        style: AppTheme.rowTitle,
      ),
    );
  }
}

class _Dial extends StatefulWidget {
  const _Dial({
    required this.bearing,
    required this.heading,
    required this.aligned,
    required this.cityName,
  });

  final double bearing;
  final double? heading;
  final bool aligned;
  final String cityName;

  @override
  State<_Dial> createState() => _DialState();
}

class _DialState extends State<_Dial> {
  bool _wasAligned = false;

  @override
  void didUpdateWidget(covariant _Dial oldWidget) {
    super.didUpdateWidget(oldWidget);
    // One tick when the housing lines up, not a burst while it stays lined up.
    if (widget.aligned && !_wasAligned) {
      HapticFeedback.mediumImpact();
    }
    _wasAligned = widget.aligned;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    // Announce the actionable state, not a repeat of the bearing line below.
    final heading = widget.heading;
    final delta = qiblaDeltaDeg(widget.bearing, heading ?? 0);
    final spoken = heading == null
        ? loc.degreesFromNorth(loc.number(widget.bearing.round()))
        : widget.aligned
            ? loc.qiblaAligned
            : delta > 0
                ? loc.qiblaTurnRight(loc.number(delta.abs().round()))
                : loc.qiblaTurnLeft(loc.number(delta.abs().round()));
    return Center(
      child: Semantics(
        label: spoken,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The dial only grows on an expanded window: at phone widths the
            // 320 dp dial keeps the hints above the fold.
            final maxDial = AppBreakpoints.isExpanded(context) ? 420.0 : 320.0;
            final size = math.min(constraints.maxWidth, maxDial);
            return SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _DialPainter(
                  colors: colors,
                  heading: widget.heading ?? 0,
                  bearing: widget.bearing,
                  aligned: widget.aligned,
                  cardinalNorth: loc.cardinalNorth,
                  cardinalEast: loc.cardinalEast,
                  cardinalSouth: loc.cardinalSouth,
                  cardinalWest: loc.cardinalWest,
                  direction: Directionality.of(context),
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: dialAngleDeg(widget.bearing, widget.heading ?? 0) /
                        360.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.navigation,
                      size: 72,
                      color: widget.aligned ? colors.secondary : colors.primary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
