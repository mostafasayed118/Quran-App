import 'package:flutter/material.dart';

class ArabicBadge extends StatelessWidget {
  const ArabicBadge(
    this.label, {
    super.key,
    this.size = 38,
    this.radius = 11,
    this.textStyle,
  });

  final String label;
  final double size;
  final double radius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: (textStyle ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.bold,
          color: colors.primary,
        ),
      ),
    );
  }
}
