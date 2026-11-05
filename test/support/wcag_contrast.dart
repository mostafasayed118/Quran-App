import 'dart:math';

double wcagRelativeLuminance(int rgb) {
  double channel(int shift) {
    final c = ((rgb >> shift) & 0xFF) / 255;
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}

double wcagContrastRatio(int a, int b) {
  final la = wcagRelativeLuminance(a);
  final lb = wcagRelativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
