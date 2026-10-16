import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/heading_service.dart';
import 'qibla_cubit.dart';
import 'qibla_state.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.qibla)),
      body: BlocBuilder<QiblaCubit, QiblaState>(
        builder: (context, state) {
          final (:city, :bearing, :heading) = switch (state) {
            QiblaReady() => (
                city: state.city,
                bearing: state.bearing,
                heading: state.heading,
              ),
          };
          if (city == null || bearing == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.noCity),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/prayer-times/city'),
                    child: Text(loc.selectCity),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(
                  city.nameAr,
                  style: const TextStyle(
                    fontFamily: QuranFonts.meQuran,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter:
                        _DialPainter(colors: Theme.of(context).colorScheme),
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
              ),
              if (heading != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    loc.compassLive,
                    style: AppTheme.mutedFootnote(context),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: Text(
                  loc.degreesFromNorth(bearing.round().toArabicIndic),
                  style: const TextStyle(
                    fontFamily: QuranFonts.meQuran,
                    fontSize: 18,
                  ),
                ),
              ),
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
