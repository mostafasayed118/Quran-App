import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/empty_state.dart';
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
  };
}

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.qibla)),
      body: BlocBuilder<QiblaCubit, QiblaState>(
        buildWhen: qiblaBodyShouldRebuild,
        builder: (context, state) {
          final (:city, :bearing, :heading, :compassUnavailable) =
              switch (state) {
            QiblaReady() => (
                city: state.city,
                bearing: state.bearing,
                heading: state.heading,
                compassUnavailable: state.compassUnavailable,
              ),
          };
          if (city == null || bearing == null) {
            return EmptyState(
              loc.noCity,
              actionLabel: loc.selectCity,
              onAction: () => context.push('/prayer-times/city'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CityTile(title: city.nameAr),
              const SizedBox(height: 8),
              _Dial(bearing: bearing, heading: heading),
              if (heading != null) ...[
                const SizedBox(height: 8),
                _CompassNote(text: loc.compassLive),
              ] else if (compassUnavailable) ...[
                const SizedBox(height: 8),
                _CompassNote(text: loc.compassStatic),
              ],
              const SizedBox(height: 16),
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
    final radius = size.shortestSide / 2 - 8;
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
        style: const TextStyle(
          fontFamily: QuranFonts.meQuran,
          fontSize: 18,
        ),
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
        style: const TextStyle(
          fontFamily: QuranFonts.meQuran,
          fontSize: 18,
        ),
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
