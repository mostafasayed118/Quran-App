part of 'qibla_screen.dart';

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
      final angle = dialTickAngleDeg(i.toDouble(), heading) * math.pi / 180.0;
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
            fontSize: AppType.micro,
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
