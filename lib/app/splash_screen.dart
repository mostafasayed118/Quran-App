import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Full-screen brand moment shown at boot on top of the routed app.
///
/// Mirrors the static native splash baked by `tools/generate_splash_mark.py`
/// (same card, glyph, rings and background) so the native window hands off to
/// the first Flutter frame without a visible seam; the wordmark, loading bar
/// and tagline fade in here.
///
/// The routed app underneath is never blocked or re-created. The overlay
/// ignores all input, holds for [hold] after mounting, fades out over [fade],
/// and then removes itself.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.child});

  /// The routed app; kept mounted (and State intact) underneath the overlay.
  final Widget child;

  /// How long the mark stays fully visible before the fade begins.
  static const Duration hold = Duration(milliseconds: 650);

  /// Fade-out duration.
  static const Duration fade = Duration(milliseconds: 350);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fade =
      AnimationController(vsync: this, value: 1, duration: SplashScreen.fade);
  late final AnimationController _bar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  Timer? _holdTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _holdTimer = Timer(SplashScreen.hold, () {
      unawaited(
        _fade.reverse().then((_) {
          if (mounted) setState(() => _dismissed = true);
        }),
      );
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _fade.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_dismissed)
          IgnorePointer(
            ignoring: true,
            child: FadeTransition(
              opacity: _fade,
              child: _SplashContent(bar: _bar),
            ),
          ),
      ],
    );
  }
}

/// Standalone test hook for the painted frame (no router, no app wiring).
@immutable
class _SplashContent extends StatelessWidget {
  const _SplashContent({required this.bar});

  final Animation<double> bar;

  static const double cardSize = 128;
  static const double cardRadius = 30;
  static const double ringScale = 1.23;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final bg = dark ? AppColors.darkBackground : AppColors.pageBackground;
    final heading = dark ? AppColors.darkOnSurface : AppColors.emeraldDark;
    final accent = dark ? AppColors.gold : AppColors.goldText;
    final footer = (dark ? AppColors.darkOnSurface : AppColors.ink)
        .withValues(alpha: dark ? .42 : .55);
    final track = dark ? AppColors.darkHairline : AppColors.hairline;
    final glowAlpha = dark ? .13 : .20;
    final ringAlpha1 = dark ? .35 : .22;
    final ringAlpha2 = dark ? .18 : .11;
    const card = Color(0xFF042C25); // matches the glyph artwork background

    return ExcludeSemantics(
      child: ColoredBox(
        color: bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Corner accents (mint top-right, gold bottom-left), softened.
            Positioned(
              top: -64,
              right: -64,
              child: _CornerGlow(
                color: const Color(0xFFA8F3C6).withValues(
                  alpha: dark ? .07 : .10,
                ),
              ),
            ),
            Positioned(
              bottom: -64,
              left: -64,
              child: _CornerGlow(
                color: const Color(0xFFFFE088).withValues(
                  alpha: dark ? .07 : .10,
                ),
              ),
            ),
            // Vignette: the canvas fades into the background at the edges.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.05,
                    colors: [bg.withValues(alpha: 0), bg],
                    stops: const <double>[0, .78],
                  ),
                ),
              ),
            ),
            // Central identity: glow + two engineered frames + card.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: cardSize * ringScale,
                    height: cardSize * ringScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Halo behind the mark.
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFFFE088)
                                    .withValues(alpha: glowAlpha),
                                const Color(0xFFFFE088).withValues(alpha: 0),
                              ],
                              stops: const <double>[0, .72],
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: 45 * math.pi / 180,
                          child: Container(
                            width: cardSize * ringScale,
                            height: cardSize * ringScale,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.gold
                                    .withValues(alpha: ringAlpha1),
                                width: 1.6,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: 22.5 * math.pi / 180,
                          child: Container(
                            width: cardSize * ringScale,
                            height: cardSize * ringScale,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.gold
                                    .withValues(alpha: ringAlpha2),
                                width: 1.6,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                        Container(
                          width: cardSize,
                          height: cardSize,
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(cardRadius),
                            border: dark
                                ? Border.all(
                                    color:
                                        AppColors.gold.withValues(alpha: .16),
                                  )
                                : null,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x6600281A),
                                blurRadius: 26,
                                offset: Offset(0, 16),
                              ),
                              BoxShadow(
                                color: Color(0x5922321D),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/icons/logo_glyph.png',
                              width: cardSize * .8,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    l10n.appName,
                    style: TextStyle(
                      fontFamily: QuranFonts.ui,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      height: 1.2,
                      letterSpacing: -.2,
                      color: heading,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'QURAN YAHDI',
                    style: TextStyle(
                      fontFamily: QuranFonts.ui,
                      fontSize: 10.5,
                      letterSpacing: 4.2,
                      color: accent.withValues(alpha: .85),
                    ),
                  ),
                  const SizedBox(height: 42),
                  _LoadingTrack(track: track, animation: bar),
                ],
              ),
            ),
            // Tagline pinned to the bottom edge.
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Center(
                child: Text(
                  l10n.splashTagline,
                  style: TextStyle(
                    fontFamily: QuranFonts.ui,
                    fontSize: 11,
                    letterSpacing: .3,
                    color: footer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerGlow extends StatelessWidget {
  const _CornerGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const <double>[0, .75],
          ),
        ),
      );
}

class _LoadingTrack extends StatelessWidget {
  const _LoadingTrack({required this.track, required this.animation});

  final Color track;
  final Animation<double> animation;

  static const double width = 56;
  static const double segment = 22;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          width: width,
          height: 3,
          child: Stack(
            children: [
              ColoredBox(color: track),
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(animation.value);
                  final left = -segment + t * (width + segment * 2);
                  return Positioned(
                    left: left,
                    top: 0,
                    bottom: 0,
                    width: segment,
                    child: const ColoredBox(color: AppColors.gold),
                  );
                },
              ),
            ],
          ),
        ),
      );
}
