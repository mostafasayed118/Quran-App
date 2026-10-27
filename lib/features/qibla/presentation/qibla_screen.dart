import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_routes.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/insets.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_pane.dart';
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
        a.heading?.round() != b.heading?.round(),
    (QiblaFailed(), QiblaFailed()) => false,
    (QiblaLoading(), QiblaLoading()) => false,
    _ => true,
  };
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
      body: BlocBuilder<QiblaCubit, QiblaState>(
        buildWhen: qiblaBodyShouldRebuild,
        builder: (context, state) {
          if (state is QiblaLoading) return const LoadingView();
          if (state is QiblaFailed) return errorPane(loc);
          final (:city, :bearing, :heading, :compassUnavailable) =
              switch (state) {
            QiblaReady() => (
                city: state.city,
                bearing: state.bearing,
                heading: state.heading,
                compassUnavailable: state.compassUnavailable,
              ),
            QiblaLoading() => (
                city: state.city,
                bearing: state.bearing,
                heading: state.heading,
                compassUnavailable: state.compassUnavailable,
              ),
            QiblaFailed() => (
                city: null,
                bearing: null,
                heading: null,
                compassUnavailable: false,
              ),
          };
          if (city == null || bearing == null) {
            return EmptyState(
              loc.noCity,
              actionLabel: loc.selectCity,
              onAction: () async {
                final selected = await context.push<bool>(AppRoutes.cityPicker);
                if (selected == true && context.mounted) {
                  await context.read<QiblaCubit>().reload();
                }
              },
            );
          }
          return ListView(
            padding:
                appScrollPadding(context, const EdgeInsets.all(AppSpacing.lg)),
            children: [
              _CityTile(title: city.nameAr),
              const SizedBox(height: AppSpacing.sm),
              _Dial(bearing: bearing, heading: heading),
              if (heading != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _CompassNote(text: loc.compassLive),
              ] else if (compassUnavailable) ...[
                const SizedBox(height: AppSpacing.sm),
                _CompassNote(text: loc.compassStatic),
              ],
              const SizedBox(height: AppSpacing.lg),
              _DegreesLabel(bearing: bearing),
            ],
          );
        },
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({required this.colors});

  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - AppSpacing.sm;
    final circle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colors.outline;
    canvas.drawCircle(center, radius, circle);

    for (var i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180.0;
      final p1 = Offset(
        center.dx + (radius - 10) * math.sin(angle),
        center.dy - (radius - 10) * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      final tick = Paint()
        ..strokeWidth = i % 90 == 0 ? 3 : 1
        ..color = i % 90 == 0 ? colors.primary : colors.outline;
      canvas.drawLine(p1, p2, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(
        title,
        style: AppTheme.meQuranTitle,
      ),
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

class _DegreesLabel extends StatelessWidget {
  const _DegreesLabel({required this.bearing});

  final double bearing;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Text(
        loc.degreesFromNorth(bearing.round().toArabicIndic),
        style: AppTheme.meQuranTitle,
      ),
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial({required this.bearing, required this.heading});

  final double bearing;
  final double? heading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: CustomPaint(
          painter: _DialPainter(colors: Theme.of(context).colorScheme),
          child: Center(
            child: AnimatedRotation(
              turns: dialAngleDeg(bearing, heading ?? 0) / 360.0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.navigation,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
