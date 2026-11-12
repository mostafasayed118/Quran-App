part of 'qibla_screen.dart';

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

  /// Unwrapped turns for the arrow: [AnimatedRotation] interpolates the
  /// number, so a 359°→0° crossing must stay a small step (not a full spin).
  late double _turns;

  double get _angle => dialAngleDeg(widget.bearing, widget.heading ?? 0);

  @override
  void initState() {
    super.initState();
    _turns = _angle / 360.0;
  }

  @override
  void didUpdateWidget(covariant _Dial oldWidget) {
    super.didUpdateWidget(oldWidget);
    // One tick when the housing lines up, not a burst while it stays lined up.
    if (widget.aligned && !_wasAligned) {
      HapticFeedback.mediumImpact();
    }
    _wasAligned = widget.aligned;

    final previous = dialAngleDeg(oldWidget.bearing, oldWidget.heading ?? 0);
    _turns += shortestAngleDeltaDeg(_angle, previous) / 360.0;
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
                    turns: _turns,
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
